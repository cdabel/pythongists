"""
Load staging table in destination database


 #####   #      ###
 #      # #      #
 #      # #      #
 ####    #       #
 #      # # #    #
 #      #  #     #
 #####   ## #   ###


This script takes the C&S PSU data from the 2 latest Excel sheets provided and
uploads it to the IHR Database server, where a SQL Server script will later
transform and union the data with other PSU data, including C&S and E&I data.

Pandas is used rather than csv to help with forcing all data types to string.
This should help to avoid having different data types within the same column
and keep value lengths consistent.

# TODO: Add logging.
"""

from pathlib import Path
import pandas as pd
# import numpy as np
import glob
import os
import sys
import pypyodbc as pypy
# import csv
import time
import datetime as dt
# import threading  # TODO: ingest both xlsx files simultaneously
# import logging    # TODO


sourcePath = Path("//nasgw096pn/operational metrics portal/Hospital Census Reports"
                  "/Analytic_Support/DM/OPTUM/PHM_I/PHI/EnI_ACO_PSU/{}")
dest_odbc_driver         = "{SQL Server Native Client 11.0}"
destination_server       = "DBVED36880"
destination_db           = "IHR_RAP"
destination_schema       = "stage"
dest_tablename_nonaco    = "PSU_EI_Latest"
dest_tablename_aco       = "PSU_EI_ACO_Latest"
destination_table_nonaco = f"""[{destination_db}].[{destination_schema}].[{dest_tablename_nonaco}]"""
destination_table_aco    = f"""[{destination_db}].[{destination_schema}].[{dest_tablename_aco}]"""
conn_str = f'''\
Driver={dest_odbc_driver};\
Server={destination_server};\
Database={destination_db};\
Trusted_Connection=yes;\
'''
rows_to_insert = []


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
    with open(latest_file, "r", newline='') as eni:
        global df_eni
        df_eni = pd.read_csv(eni, dtype=str, sep='\t')
        df_eni.columns = df_eni.columns.str.strip()   # remove whitespace around column names
        df_eni = df_eni.astype(str)
        df_eni = df_eni.applymap(str.strip)           # remove whitespace around values
        # df_enifile = df_enifile.replace('', np.nan)         # map nans, to drop NAs rows and columns later
        # df_enifile = df_enifile.dropna(how='all', axis=0)   # remove rows containing only NAs
        # df_enifile = df_enifile.dropna(how='all', axis=1)   # remove columns containing only NAs
        # df_enifile = df_enifile.replace(np.nan, 'NA')       # turbodbc hates null values...
        return df_eni.columns.values.tolist(), df_eni.values.tolist()


# Execute a query
def runquery(querystr):
    try:
        cursor.execute(querystr)
        conn.commit()
    except pypy.ProgrammingError:
        pass


def run_insert_query(rowcount, rowlist, latest_file_name_ext, ins_query, context, rowlimit):
    if (rowcount == 0):
        global rows_to_insert
        rows_to_insert = rowlist[0:rowlimit]
        for r in range(len(rows_to_insert)):
            rows_to_insert[r].append(dt.datetime.now())
            rows_to_insert[r].append(latest_file_name_ext)
        print(f"Executing {context} bulk insert...")
        cursor.fast_executemany = True
        cursor.executemany(ins_query, rows_to_insert)
    else:
        raise Exception(f"Target {context} table not empty. Exiting to prevent dupes.")
        sys.exit()


#
#       ###    ###   #
#      #   #  #   #  #
#      #      #   #  #
#       ###   #   #  #
#          #  #   #  #
#      #   #  # # #  #
#       ###    ###   #####
#                 #

# Non-ACO
qdrop_nonaco = f"""DROP TABLE IF EXISTS {destination_table_nonaco}"""
# `date_ingested` to be calculated upon ingestion
qcreate_nonaco = f"""
CREATE TABLE {destination_table_nonaco} (   -- | Final table data types:
  MBR_ID                varchar(50)    NULL -- | -----------------------
, indv_id               varchar(50)    NULL -- |
, age                   varchar(10)    NULL -- | varchar(3)
, dob                   varchar(20)    NULL -- | varchar(10)
, MBR_FST_NM            varchar(255)   NULL -- |
, MBR_LST_NM            varchar(255)   NULL -- |
, MBR_GDR_CD            varchar(10)    NULL -- | varchar(1)
, MKT_RLLP_NM           varchar(255)   NULL -- |
, MKT_SEG_CD            varchar(10)    NULL -- | varchar(3)
, CUST_SEG_NBR          varchar(10)    NULL -- |
, Exchange_Ind          varchar(10)    NULL -- | varchar(1)
, MBR_ZIP_CD            varchar(10)    NULL -- | varchar(10)
, MBR_CTY_NM            varchar(255)   NULL -- |
, MBR_HCFA_CNTY_NM      varchar(255)   NULL -- |
, MBR_ST_ABBR_CD        varchar(10)    NULL -- | varchar(2)
, pred                  varchar(20)    NULL -- |
, pred_flag             varchar(10)    NULL -- | varchar(1)
, pred_cutoff           varchar(20)    NULL -- |
, RCT                   varchar(10)    NULL -- | varchar(1)
, chf                   varchar(10)    NULL -- | varchar(1)
, esrd                  varchar(10)    NULL -- | varchar(1)
, date_ingested         varchar(30)    NULL -- |
, FileName              varchar(255)   NULL -- |
)"""


# ACO
qdrop_aco = f"""DROP TABLE IF EXISTS {destination_table_aco}"""
# `date_ingested` to be calculated upon ingestion
qcreate_aco = f"""
CREATE TABLE {destination_table_aco} ( --  | Final table data types:
  MBR_ID           varchar(50)    NULL --  | -----------------------
, referral         varchar(20)    NULL --  |
, condition_count  varchar(20)    NULL --  |
, pred_flag        varchar(10)    NULL --> | varchar(1)
, year_mo          varchar(10)    NULL --  |
, MKT_RLLP_NM      varchar(255)   NULL --  |
, PRSPCTV_RISK     varchar(10)    NULL --  |
, pred             varchar(20)    NULL --  |
, CUST_SEG_NBR     varchar(50)    NULL --> | varchar(10)
, chf              varchar(10)    NULL --> | varchar(1)
, esrd             varchar(10)    NULL --> | varchar(1)
, indv_id          varchar(50)    NULL --  |
, group_nm         varchar(255)   NULL --  |
, ACO              varchar(10)    NULL --> | varchar(1)
, Exchange_ind     varchar(10)    NULL --> | varchar(1)
, aco_flag         varchar(10)    NULL --> | varchar(1)
, date_ingested    varchar(30)    NULL --> | varchar(10)
, FileName         varchar(255)   NULL --  |
)"""


#
#   ####   #   #  ###  #     ####       ###  #   #   ###  ##### ####  #####
#    #  #  #   #   #   #      #  #       #   #   #  #   # #     #   #   #
#    #  #  #   #   #   #      #  #       #   ##  #  #     #     #   #   #
#    ###   #   #   #   #      #  #       #   # # #   ###  ####  ####    #
#    #  #  #   #   #   #      #  #       #   #  ##      # #     # #     #
#    #  #  #   #   #   #      #  #       #   #   #  #   # #     #  #    #
#   ####    ###   ###  ##### ####       ###  #   #   ###  ##### #   #   #
#

# Non-ACO      - Get latest eni file
latest_nonaco, latest_nonaco_name_ext = get_files("EnI_PSU*.txt")
cols_to_update_nonaco, nonaco_rows_list = read_in_files(latest_nonaco, latest_nonaco_name_ext)
cols_to_update_nonaco.append("date_ingested")
cols_to_update_nonaco.append("FileName")

# ACO  - Get latest aco file
latest_aco, latest_aco_name_ext = get_files("EnI_ACO_PSU*.txt")
cols_to_update_aco, aco_rows_list = read_in_files(latest_aco, latest_aco_name_ext)
cols_to_update_aco.append("date_ingested")
cols_to_update_aco.append("FileName")


# Generate series of parameters for INSERT statements
# NonACO
param_builder_nonaco = "?"
for i in range(len(cols_to_update_nonaco) - 1):  # minus 1 since it initialized with 1
    param_builder_nonaco += ", ?"  # 23 items total

# ACO
param_builder_aco = "?"
for i in range(len(cols_to_update_aco) - 1):  # minus 1 since it initialized with 1
    param_builder_aco += ", ?"  # 18 items total


# Build INSERT statements
# Non-ACO
strofcols_nonaco = ",\n  ".join(cols_to_update_nonaco)  # print(strofcols)
qinsert_nonaco = f"""
INSERT INTO {destination_table_nonaco}
( {strofcols_nonaco} )
VALUES ( {param_builder_nonaco} )
"""  # print(qinsert_nonaco)

# ACO
strofcols_aco = ",\n  ".join(cols_to_update_aco)  # print(strofcols)
qinsert_aco = f"""
INSERT INTO {destination_table_aco}
( {strofcols_aco} )
VALUES ( {param_builder_aco} )
"""  # print(qinsert_aco)


# BEGIN Database transactions

# Open connection/cursor
conn = pypy.connect(conn_str)
cursor = conn.cursor()

#
#      #   #   ###   #   #           #     ###    ###
#      #   #  #   #  #   #          # #   #   #  #   #
#      ##  #  #   #  ##  #         #   #  #      #   #
#      # # #  #   #  # # #  #####  #   #  #      #   #
#      #  ##  #   #  #  ##         #####  #      #   #
#      #   #  #   #  #   #         #   #  #   #  #   #
#      #   #   ###   #   #         #   #   ###    ###
#

# Prep staging tables
runquery(qdrop_nonaco)    # drop stage table if it exists (supported on SQL Server 2016+)
runquery(qcreate_nonaco)  # create staging table
conn.commit()


# Check existing rowcounts of target tables
cursor.execute(f"SELECT count(*) FROM {destination_table_nonaco}")
rowcount_nonaco_pre = cursor.fetchone()
rowcount_nonaco_pre = rowcount_nonaco_pre[0]


# Execute INSERTS
total_rows_to_insert_nonaco = len(nonaco_rows_list)
start_time_nonaco = time.time()  # START TIMER

rows_to_insert.clear()
run_insert_query(rowcount_nonaco_pre,
                 nonaco_rows_list,
                 latest_nonaco_name_ext,
                 qinsert_nonaco,
                 "non-ACO",
                 total_rows_to_insert_nonaco)
conn.commit()

end_time_nonaco = time.time()  # END TIMER
elapsed_time_nonaco = str(round(end_time_nonaco - start_time_nonaco, 1))
print('Non-ACO: INSERTS Completed in {} seconds'.format(elapsed_time_nonaco))

# Get final rowcounts of target table
cursor.execute(f"SELECT count(*) FROM {destination_table_nonaco}")
rowcount_nonaco_post = cursor.fetchone()
rowcount_nonaco_post = rowcount_nonaco_post[0]

# Ensure all rows imported successfully
total_rows_inserted_nonaco = rowcount_nonaco_post
row_diff_nonaco = total_rows_to_insert_nonaco - total_rows_inserted_nonaco
if (row_diff_nonaco > 0):
    raise Exception('{} rows failed to insert.'.format(row_diff_nonaco))


#
#        #     ###    ###
#       # #   #   #  #   #
#      #   #  #      #   #
#      #   #  #      #   #
#      #####  #      #   #
#      #   #  #   #  #   #
#      #   #   ###    ###
#

# Prep staging table
runquery(qdrop_aco)       # drop stage table if it exists (supported on SQL Server 2016+)
runquery(qcreate_aco)     # create staging table
conn.commit()

# Check existing rowcounts of target table
cursor.execute(f"SELECT count(*) FROM {destination_table_aco}")
rowcount_aco_pre = cursor.fetchone()
rowcount_aco_pre = rowcount_aco_pre[0]

# Execute INSERT
total_rows_to_insert_aco = len(aco_rows_list)
start_time_aco = time.time()  # START TIMER

rows_to_insert.clear()
run_insert_query(rowcount_aco_pre,
                 aco_rows_list,
                 latest_aco_name_ext,
                 qinsert_aco,
                 "ACO",
                 total_rows_to_insert_aco)
conn.commit()

end_time_aco = time.time()  # END TIMER
elapsed_time_aco = str(round(end_time_aco - start_time_aco, 1))
print('ACO: INSERTS Completed in {} seconds'.format(elapsed_time_aco))

# Get final rowcounts of target table
cursor.execute(f"SELECT count(*) FROM {destination_table_aco}")
rowcount_aco_post = cursor.fetchone()
rowcount_aco_post = rowcount_aco_post[0]


cursor.close()
conn.close()

# Ensure all rows imported successfully
total_rows_inserted_aco = rowcount_aco_post
row_diff_aco = total_rows_to_insert_aco - total_rows_inserted_aco
if (row_diff_aco > 0):
    raise Exception('{} rows failed to insert.'.format(row_diff_aco))

print('E&I (ACO) job completed | {} rows failed to insert.'.format(row_diff_aco))

sys.exit('Both files imported:\n'
         ' - {} non-ACO rows failed to insert.\n'
         ' - {} ACO rows failed to insert.'
         .format(row_diff_nonaco, row_diff_aco))
