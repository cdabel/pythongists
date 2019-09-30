"""
Load staging table in destination database


 #   #     #       ####
 #   #    # #      #   #
 ## ##    # #      #   #
 # # #     #       ####
 #   #    # # #    # #
 #   #    #  #     #  #
 #   #     ## #    #   #


This script takes the M&R PSU data from the latest Excel sheet provided and
uploads it to the IHR Database server, where a SQL Server script will later
transform and union the data with other PSU data, including C&S and E&I data.

# TODO: Add logging.
"""

from pathlib import Path
import glob
import os
import sys
import pypyodbc as pypy
import xlrd
import time
import datetime as dt
# import logging    # TODO


sourcePath = Path("//nasgw096pn/operational metrics portal/Hospital Census Reports"
                  "/Analytic_Support/DM/OPTUM/PHM_I/PHI/MnR_PCCM/{}")
destination_server   = "DBVED36880"
destination_db       = "IHR_RAP"
destination_schema   = "stage"
dest_tablename       = "PSU_MR_Latest"
dest_odbc_driver     = "{SQL Server Native Client 11.0}"
destination_table    = f"[{destination_db}].[{destination_schema}].[{dest_tablename}]"


conn_str = f'''\
Driver={dest_odbc_driver};\
Server={destination_server};\
Database={destination_db};\
Trusted_Connection=yes;\
'''


# Execute a query
def runquery(querystr):
    try:
        cursor.execute(querystr)
        conn.commit()
    except pypy.ProgrammingError:
        pass


# Find and return latest report
listReports = glob.glob(str(sourcePath).format("*.xlsx"))
latestReport = max(listReports, key=os.path.getctime)
latestReportNameExt = os.path.basename(latestReport)
latestReportName, latestReportExtension = os.path.splitext(latestReportNameExt)


# Read in worksheet
print('Reading in file {}'.format(latestReport))
book = xlrd.open_workbook(latestReport)
global book_datemode
book_datemode = book.datemode
sheet = book.sheet_by_index(0)


# SQL QUERIES
qdrop = f"""DROP TABLE IF EXISTS {destination_table}"""
# `datetime_ingested` to be calculated upon ingestion
qcreate = f"""
CREATE TABLE {destination_table} (
    hicn                           varchar(50)    NULL  -- Final data type needed:
  , bth_dt                         varchar(10)    NULL
  , GPS_FIRST_NAME                 varchar(255)   NULL
  , GPS_LAST_NAME                  varchar(255)   NULL
  , FIN_GENDER                     varchar(1)     NULL
  , gps_zip_cd                     varchar(9)     NULL
  , GPS_ADDRESS_LINE_1             varchar(255)   NULL
  , GPS_CITY                       varchar(255)   NULL
  , FIN_STATE                      varchar(2)     NULL
  , GPS_DAYTIME_PHONE_NUM          varchar(12)    NULL
  , fin_county_name                varchar(255)   NULL
  , FIN_ESRD_FLAG                  varchar(1)     NULL
  , hospice                        varchar(255)   NULL
  , GPS_SPOKEN_LANGUAGE_NAME       varchar(50)    NULL
  , GPS_DO_NOT_CALL                varchar(1)     NULL
  , aco_flag                       varchar(1)     NULL -- bit
  , PMG_NAME                       varchar(80)    NULL
  , FIN_CONTRACT_NBR               varchar(10)    NULL
  , FIN_PBP                        varchar(3)     NULL
  , product                        varchar(50)    NULL
  , FIN_DERIVED_MCAID_STATUS_FLG   varchar(1)     NULL
  , age                            varchar(3)     NULL -- tinyint
  , hcc                            varchar(50)    NULL -- DECIMAL(5,3)
  , paid_r12                       varchar(50)    NULL -- DECIMAL(10,2)
  , pred_cutoff                    varchar(50)    NULL -- DECIMAL(10,2)
  , pred                           varchar(50)    NULL -- DECIMAL(10,2)
  , pred_flag                      varchar(1)     NULL -- bit
  , ip_acute_cnt                   varchar(3)     NULL -- tinyint
  , ip_pd_amt                      varchar(50)    NULL -- DECIMAL(10,2)
  , op_er_cnt                      varchar(3)     NULL -- tinyint
  , op_er_pd_amt                   varchar(20)    NULL -- DECIMAL(10,2)
  , gps_new_group_number           varchar(50)    NULL
  , FIN_G_I                        varchar(5)     NULL
  , CHF_eng                        varchar(20)    NULL -- int
  , DIAB_eng                       varchar(20)    NULL -- int
  , ESRD_eng                       varchar(20)    NULL -- int
  , TCM_eng                        varchar(20)    NULL -- int
  , HRCM_eng                       varchar(20)    NULL -- int
  , AI_eng                         varchar(20)    NULL -- int
  , chronic                        varchar(2000)  NULL
  , institutional                  varchar(1)     NULL
  , agecat                         varchar(15)    NULL
  , hicn_old                       varchar(50)    NULL
  , ASGN_TO_USER_ID                varchar(10)    NULL
  , external_care_manager          varchar(50)    NULL
  , case_manager                   varchar(50)    NULL
  , ANY_OPTUM_PGM                  varchar(20)    NULL -- int
  , date_ingested                  varchar(30)    NULL
  , FileName                       varchar(255)   NULL -- source file name
)"""


# Extract list of column headers
cols_to_update = []
for col in range(sheet.ncols):
    cols_to_update.append(sheet.cell_value(0, col))

cols_to_update.append("date_ingested")
cols_to_update.append("FileName")
# REVIEW:  Modify below if columns need to be excluded:
# cols_to_update.remove("chronic")


# Generate series of parameters for INSERT statement
param_builder = "?"
for i in range(len(cols_to_update) - 1):  # minus 1 since param_builder initialized with 1
    param_builder += ", ?"                # print(param_builder)


# Build INSERT statement
strofcols = ",\n  ".join(cols_to_update)  # print(strofcols)
qinsert = f"""
INSERT INTO {destination_table}
( {strofcols} )
VALUES ( {param_builder} )
"""                                       # print(qinsert)


# Open connection/cursor
conn = pypy.connect(conn_str)
cursor = conn.cursor()


# Prep staging table
runquery(qdrop)    # drop stage table if it exists (supported on SQL Server 2016+)
runquery(qcreate)  # create staging table
conn.commit()


# Check existing rowcount of table
cursor.execute(f"SELECT count(*) FROM {destination_table}")
rowcount_pre = cursor.fetchone()  # should be 0

# Extract list of column headers
xlsx_header_row = []
for col in range(sheet.ncols):
    xlsx_header_row.append(sheet.cell_value(0, col))

# Execute INSERTS
total_rows_to_insert = sheet.nrows - 1  # Minus header row

start_time = time.time()  # START TIMER
list_of_lists = []

# REVIEW:  Modify this if columns need to be excluded:
if (rowcount_pre[0] == 0):
    for r in range(1, sheet.nrows):
        global list_values                                    # (global for debugging only)
        list_values = []
        for index, column_name in enumerate(xlsx_header_row):
            # # REVIEW:  Exclude columns from iteration:
            # if index == xlsx_header_row.index('chronic'):
            #     continue
            if sheet.cell(r, index).ctype == 3:               # 3 means 'xldate'
                datenumber = sheet.cell(r, index).value
                # book_datemode = 0 --> The file's Excel numbering system for dates
                year, month, day, hour, minute, second = xlrd.xldate_as_tuple(datenumber, book_datemode)
                cell_value = dt.date(year, month, day)
                list_values.append(cell_value)
                continue
            else:
                cell_value = sheet.cell(r, index).value
                list_values.append(cell_value)
                continue
        list_values.append(dt.datetime.now())
        list_values.append(latestReportNameExt)
        list_of_lists.append(list_values)
    print("Parameter sequencing completed...")
    cursor.fast_executemany = True
    print("Executing bulk insert...")
    cursor.executemany(qinsert, list_of_lists)
else:
    raise Exception("Target table not empty. Exiting to prevent dupes.")
    sys.exit()

conn.commit()

end_time = time.time()  # END TIMER
elapsed_time = end_time - start_time
print('{} INSERTS Completed in {} seconds'.format(total_rows_to_insert, elapsed_time))

# Ensure all rows imported successfully
cursor.execute(f"SELECT count(*) FROM {destination_table}")
rowcount_post = cursor.fetchone()

cursor.close()
conn.close()


# Ensure all rows imported successfully
total_rows_inserted = rowcount_post[0]
row_diff = total_rows_to_insert - total_rows_inserted
if (row_diff > 0):
    raise Exception('{} rows failed to insert'.format(row_diff))

# TODO: Uncomment before publishing
print('M&R job completed | {} rows failed to insert.'.format(row_diff))
sys.exit(0)