"""
Load staging table in destination database


  ###      #        ###
 #   #    # #      #   #
 #        # #      #
 #         #        ###
 #        # # #        #
 #   #    #  #     #   #
  ###      ## #     ###


This script takes the C&S PSU data from the 2 latest Excel sheets provided and
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
# import threading  # TODO: ingest both xlsx files simultaneously
# import logging    # TODO


sourcePath = Path("//nasgw096pn/operational metrics portal/Hospital Census Reports"
                  "/Analytic_Support/DM/OPTUM/PHM_I/PHI/PSU_Lists/TRANSFER/DONE/{}")
destination_server   = "DBVED36880"
destination_db       = "IHR_RAP"
destination_schema   = "stage"
dest_tablename       = "PSU_CS_Latest"
dest_odbc_driver     = "{SQL Server Native Client 11.0}"
destination_table    = f"[{destination_db}].[{destination_schema}].[{dest_tablename}]"


conn_str = f'''\
Driver={dest_odbc_driver};\
Server={destination_server};\
Database={destination_db};\
Trusted_Connection=yes;\
'''


# Get Files
def get_files(search_pattern):
    list_reports = glob.glob(str(sourcePath).format("{}".format(search_pattern)))
    latest_file = max(list_reports, key=os.path.getctime)
    latest_file_name_ext = os.path.basename(latest_file)
    return latest_file, latest_file_name_ext


# Read in worksheets
def read_in_files(latest_file, latest_file_name_ext):
    latest_file_name, latest_file_extension = os.path.splitext(latest_file_name_ext)
    print('Reading in file {}'.format(latest_file))
    book = xlrd.open_workbook(latest_file)
    global book_datemode
    book_datemode = book.datemode
    return book.sheet_by_index(0)


# Execute a query
def runquery(querystr):
    try:
        cursor.execute(querystr)
        conn.commit()
    except pypy.ProgrammingError:
        pass


def get_file_origin(sheet):
    if sheet.name == mcr_sheet.name:
        return 'mcr'
    elif sheet.name == mcd_sheet.name:
        return 'mcd'


# This function checks if rowcount of destination table equals zero before
# generating and inserting lists.
def run_insert_query(sheet, latest_file_name_ext):
    mcr_or_mcd = get_file_origin(sheet)
    # Extract list of column headers (headers are the same in MCR and MCD)
    xlsx_header_row = []
    for col in range(mcd_sheet.ncols):
        xlsx_header_row.append(mcd_sheet.cell_value(0, col))
    # global list_of_lists
    list_of_lists = []
    if (rowcount_pre[0] == 0):
        for r in range(1, sheet.nrows):
            # global list_values
            list_values = []
            for index, column_name in enumerate(xlsx_header_row):
                if sheet.cell(r, index).ctype == 3:   # 3 means 'xldate'
                    datenumber = sheet.cell(r, index).value
                    # book_datemode => which numbering system for dates (0 or 1):
                    year, month, day, hour, minute, second = xlrd.xldate_as_tuple(datenumber, book_datemode)
                    # global cell_value
                    cell_value = dt.date(year, month, day)      # Store as python date format
                    list_values.append(cell_value)
                    continue
                else:
                    cell_value = sheet.cell(r, index).value
                    list_values.append(cell_value)
                    continue
            list_values.append(mcr_or_mcd)
            list_values.append(dt.datetime.now())
            list_values.append(latest_file_name_ext)
            list_of_lists.append(list_values)
        print("Parameter sequencing completed...")
        cursor.fast_executemany = True
        print("Executing bulk insert...")
        cursor.executemany(qinsert, list_of_lists)
    else:
        raise Exception("Target table not empty. Exiting to prevent dupes.")
        sys.exit()


# MCR - Get latest mcr list / Read in mcr worksheet
latest_mcr, latest_mcr_name_ext = get_files("mcr*.xlsx")
mcr_sheet = read_in_files(latest_mcr, latest_mcr_name_ext)

# MCD - Get latest mcd list / Read in mcd worksheet
latest_mcd, latest_mcd_name_ext = get_files("mcd*.xlsx")
mcd_sheet = read_in_files(latest_mcd, latest_mcd_name_ext)


# Extract list of column headers (headers are the same in MCR and MCD)
cols_to_update = []
for col in range(mcd_sheet.ncols):
    cols_to_update.append(mcd_sheet.cell_value(0, col))

cols_to_update.append("file_origin")
cols_to_update.append("date_ingested")
cols_to_update.append("FileName")


# SQL QUERIES
qdrop = f"""DROP TABLE IF EXISTS {destination_table}"""
# `file_origin` and `datetime_ingested` to be calculated upon ingestion
qcreate = f"""
CREATE TABLE {destination_table} (
    year_mo             varchar(10)    NULL
  , Member_Key          varchar(50)    NULL
  , COMPANY_DESC        varchar(50)    NULL
  , pred_model          varchar(50)    NULL
  , pred_model_cutoff   varchar(50)    NULL
  , pred_model_flag     varchar(1)     NULL
  , Member_First_Name   varchar(255)   NULL
  , Member_Last_Name    varchar(255)   NULL
  , Member_DOB          varchar(10)    NULL
  , Subscriber_ID       varchar(50)    NULL
  , Member_City         varchar(50)    NULL
  , Member_State        varchar(10)    NULL
  , Member_Zip          varchar(10)    NULL
  , Member_Sex          varchar(10)    NULL
  , HCFA_CNTY_NM        varchar(3)     NULL
  , file_origin         varchar(3)     NULL
  , date_ingested       varchar(30)    NULL
  , FileName            varchar(255)   NULL
)"""


# Generate series of parameters for INSERT statement
param_builder = "?"
for i in range(len(cols_to_update) - 1):  # minus 1 since param_builder initializes with 1
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
rowcount_pre = cursor.fetchone()


# Execute INSERTS
total_rows_to_insert = (mcr_sheet.nrows + mcd_sheet.nrows) - 2  # Minus 2 header rows

# START TIMER
start_time = time.time()
run_insert_query(mcr_sheet, latest_mcr_name_ext)  # mcr inserts
conn.commit()
run_insert_query(mcd_sheet, latest_mcd_name_ext)  # mcd inserts
conn.commit()
end_time = time.time()
# END TIMER

elapsed_time = str(round(end_time - start_time, 1))
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
    raise Exception('{} rows failed to insert.'.format(row_diff))

sys.exit('C&S job completed | {} rows failed to insert.'.format(row_diff))
