"""
#   #  ####   #####
#   #   #  #  #
## ##   #  #  #
# # #   #  #  ####
#   #   #  #  #
#   #   #  #  #
#   #  ####   #####


Master Data Extract
Author:        Chris Dabel
Date Created:  10/02/2019

DESCRIPTION:
      This file takes the data from the latest Master Data Extract (MDE) file located at:
      `//nasv0403/ihr_prod/Ingest_Storage/MDE` and inserts it into the IHR_RAP SQL Server
      Database table called "[IHR].[Master_Data_Extract]".
"""

from pathlib import Path
import subprocess as sp
import glob
import os
import urllib
import sqlalchemy as sql
import pandas as pd
import sys
import pyodbc as py
import time
import datetime as dt


dest_odbc_driver    = "{SQL Server Native Client 11.0}"
destination_server  = "DBVED36880"
destination_db      = "IHR_RAP"
destination_schema  = "stage"
dest_tablename      = "Master_Data_Extract_MnR_Latest"
destination_table   = f"""[{destination_db}].[{destination_schema}].[{dest_tablename}]"""
conn_str            = f'''\
Driver={dest_odbc_driver};\
Server={destination_server};\
Database={destination_db};\
Trusted_Connection=yes;\
'''
conn_quoted = urllib.parse.quote_plus(conn_str)


# Source Paths:
SOURCE_PATH         = Path("//nasv0403/ihr_prod/Ingest_Storage/MDE/{}")
SOURCE_PATH_STR     = str(SOURCE_PATH.resolve())
CWD_SOURCE_PATH_STR = '//nasv0403/ihr_prod/Ingest_Storage/MDE'  # (to set CWD of subprocess)

EXE7ZIP_PATH      = Path("C:\\Program Files\\7-Zip\\7z.exe")
EXE7ZIP_PATH_STR  = str(EXE7ZIP_PATH.resolve())


# SQL ALCHEMY ENGINE
engine = sqlalchemy.create_engine("mssql+pyodbc:///?odbc_connect={}".format(conn_quoted),
                                  fast_executemany=True)

# Get File
def get_files(search_pattern):
    # global list_files
    list_files = glob.glob(SOURCE_PATH_STR.format(search_pattern))
    latest_file = max(list_files, key=os.path.getctime)
    latest_file_name_ext = os.path.basename(latest_file)
    return latest_file, latest_file_name_ext

# TODO: Refactor to have pandas unzip and read file inside read_in_files()
def unzip_file(zipname):
    # Execute cmd command:  7z e "<zip file path>" oc:\<...working dir path...>
    system = sp.Popen([EXE7ZIP_PATH_STR, "e", zipname, "-y"], cwd=CWD_SOURCE_PATH_STR)
    return(system.communicate())


# Read in worksheets
def read_in_files(latest_file, latest_file_name_ext):
    latest_file_name, latest_file_extension = os.path.splitext(latest_file_name_ext)
    print('Reading in file {}'.format(latest_file))
    with open(latest_file, "r", newline='') as file:
        global df_data
        df_data = pd.read_csv(file,
                              dtype=str,
                              sep='|',
                              error_bad_lines=False,
                              warn_bad_lines=True,
                              # memory_map=True,
                              )
        df_data.columns = df_data.columns.str.strip()         # remove whitespace around column names
        df_data = df_data.astype(str)
        df_data = df_data.applymap(str.strip)                 # remove whitespace around values
        # df_enifile = df_enifile.replace('', np.nan)         # map nans, to drop NAs rows and columns later
        # df_enifile = df_enifile.dropna(how='all', axis=0)   # remove rows containing only NAs
        # df_enifile = df_enifile.dropna(how='all', axis=1)   # remove columns containing only NAs
        # df_enifile = df_enifile.replace(np.nan, 'NA')       # turbodbc hates null values...
        return df_data.columns.values.tolist(), df_data.values.tolist()


# Execute a query
def runquery(querystr):
    try:
        cursor.execute(querystr)
        conn.commit()
    except py.ProgrammingError:
        pass


# def run_insert_query(rowcount, rowlist, latest_file_name_ext, ins_query, context, rowlimit):
#     if (rowcount == 0):
#         global rows_to_insert
#         rows_to_insert = rowlist[0:rowlimit]
#         for r in range(len(rows_to_insert)):
#             rows_to_insert[r].append(dt.datetime.now())
#             rows_to_insert[r].append(latest_file_name_ext)
#         print(f"Executing {context} bulk insert...")
#         cursor.fast_executemany = True
#         cursor.executemany(ins_query, rows_to_insert)
#     else:
#         raise Exception(f"Target {context} table not empty. Exiting to prevent dupes.")
#         sys.exit()


#
#   ##### #   # ##### ####     #     ###  #####     #####  ###  #     #####
#   #     #   #   #   #   #   # #   #   #   #       #       #   #     #
#   #      # #    #   #   #  #   #  #       #       #       #   #     #
#   ####    #     #   ####   #   #  #       #       ####    #   #     ####
#   #      # #    #   # #    #####  #       #       #       #   #     #
#   #     #   #   #   #  #   #   #  #   #   #       #       #   #     #
#   ##### #   #   #   #   #  #   #   ###    #       #      ###  ####  #####
# 
latest_file, latest_name_ext = get_files("Master_Extract_Data_Mart_*.zip")
unzip_file(latest_file)
latest_file, latest_name_ext = get_files("Master_Extract_Data_Mart_*.txt")

#
#   ####   #   #  ###  #    ####        ####   #####
#    #  #  #   #   #   #     #  #        #  #  #
#    #  #  #   #   #   #     #  #        #  #  #
#    ###   #   #   #   #     #  #        #  #  ####
#    #  #  #   #   #   #     #  #        #  #  #
#    #  #  #   #   #   #     #  #        #  #  #
#   ####    ###   ###  #### ####        ####   #
#
cols_to_update, rows_list = read_in_files(latest_file, latest_name_ext)
cols_to_update.append("Date_Ingested")
cols_to_update.append("FileName")


# #   ####   #   #  ###  #     ####       ###  #   #   ###  ##### ####  #####
# #    #  #  #   #   #   #      #  #       #   #   #  #   # #     #   #   #
# #    #  #  #   #   #   #      #  #       #   ##  #  #     #     #   #   #
# #    ###   #   #   #   #      #  #       #   # # #   ###  ####  ####    #
# #    #  #  #   #   #   #      #  #       #   #  ##      # #     # #     #
# #    #  #  #   #   #   #      #  #       #   #   #  #   # #     #  #    #
# #   ####    ###   ###  ##### ####       ###  #   #   ###  ##### #   #   #
# #
# # Generate series of parameters for INSERT statements
# param_builder = "?"
# for i in range(len(cols_to_update) - 1):  # minus 1 since it initialized with 1
#     param_builder += ", ?"

# # Build INSERT statements
# strofcols = ",\n  ".join(cols_to_update)  # print(strofcols)
# qinsert = f"""
# INSERT INTO {destination_table}
# ( {strofcols} )
# VALUES ( {param_builder} )
# """  # print(qinsert)


# #  
# #     ###    ###   #   #  #   #  #####          ####   ####   #####
# #    #   #  #   #  #   #  #   #    #            #   #  #   #  #
# #    #      #   #  #   #  ##  #    #            #   #  #   #  #
# #    #      #   #  #   #  # # #    #    #####   ####   ####   ####
# #    #      #   #  #   #  #  ##    #            #      # #    #
# #    #   #  #   #  #   #  #   #    #            #      #  #   #
# #     ###    ###    ###   #   #    #            #      #   #  #####
# #
# #  TODO: Replace with SQL Alchemy code 
# conn = py.connect(conn_str)
# cursor = conn.cursor()
# # Check existing rowcounts of target tables
# cursor.execute(f"SELECT count(*) FROM {destination_table}")
# rowcount_pre = cursor.fetchone()
# rowcount_pre = rowcount_pre[0]
# cursor.close()
# conn.close()


#
#    ###  #   #   ###   #### ####  #####  ###
#     #   #   #  #   #  #    #   #   #   #   #
#     #   ##  #  #      #    #   #   #   #
#     #   # # #   ###   ###  ####    #    ###
#     #   #  ##      #  #    # #     #       #
#     #   #   #  #   #  #    #  #    #   #   #
#    ###  #   #   ###   #### #   #   #    ###
#
total_rows_to_insert = 10000  # len(rows_list)
start_time = time.time()      # START TIMER

# Drop/Replace staging table and insert in one step
qcreate = df_data.to_sql(dest_tablename,
                         con=engine,
                         schema="stage",
                         if_exists="replace",
                         index=False,
                         # chunksize=10000,
                         method=None,  # Ensures cursor.executemany() is used
                         )

end_time = time.time()  # END TIMER
elapsed_time = str(round(end_time - start_time, 1))
print("MDE's {} INSERTS Completed in {} seconds".format(total_rows_to_insert, elapsed_time))

# Get final rowcounts of target table
conn = py.connect(conn_str)
cursor = conn.cursor()
cursor.execute(f"SELECT count(*) FROM {destination_table}")
rowcount_post = cursor.fetchone()
rowcount_post = rowcount_post[0]
cursor.close()
conn.close()


#
#   #   #    #    #     ###  ####     #   ##### #####
#   #   #   # #   #      #    #  #   # #    #   #
#   #   #  #   #  #      #    #  #  #   #   #   #
#    # #   #   #  #      #    #  #  #   #   #   ####
#    # #   #####  #      #    #  #  #####   #   #
#    # #   #   #  #      #    #  #  #   #   #   #
#     #    #   #  ####  ###  ####   #   #   #   #####
#
total_rows_inserted = rowcount_post
row_diff = total_rows_to_insert - total_rows_inserted
if (row_diff > 0):
    raise Exception('{} rows failed to insert.'.format(row_diff))


print('File imported successfully:\n'
      ' - {} rows failed to insert.\n'
      .format(row_diff))

# sys.exit(0)
