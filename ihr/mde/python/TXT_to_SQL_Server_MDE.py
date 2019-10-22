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
from urllib import parse
import subprocess as sp
import glob
import os
import sqlalchemy as sql
import pandas as pd
import sys
import pyodbc as py
import time
import datetime as dt
import gc


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
conn_quoted = parse.quote_plus(conn_str)


# Source Paths:
SOURCE_PATH         = Path("//nasv0403/ihr_prod/Ingest_Storage/MDE/{}")
SOURCE_PATH_STR     = str(SOURCE_PATH.resolve())
CWD_SOURCE_PATH_STR = '//nasv0403/ihr_prod/Ingest_Storage/MDE'  # (to set CWD of subprocess)

EXE7ZIP_PATH      = Path("C:\\Program Files\\7-Zip\\7z.exe")
EXE7ZIP_PATH_STR  = str(EXE7ZIP_PATH.resolve())


# SQL ALCHEMY ENGINE
engine = sql.create_engine("mssql+pyodbc:///?odbc_connect={}".format(conn_quoted),
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


def unzip_ifdiff(zip_pattern, txt_pattern):
    latest_zipfile, latest_zipname_ext = get_files(zip_pattern)
    latest_txtfile, latest_txtname_ext = get_files(txt_pattern)
    latest_zip_name, latest_zip_ext    = os.path.splitext(latest_zipname_ext)
    latest_txt_name, latest_txt_ext    = os.path.splitext(latest_txtname_ext)
    if latest_txt_name != latest_zip_name:
        unzip_file(latest_zipfile)
        return get_files("Master_Extract_Data_Mart_*.txt")
    else:
        return latest_txtfile, latest_txtname_ext


# Read in worksheets
def read_in_files(latest_file, latest_file_name_ext):
    latest_file_name, latest_file_extension = os.path.splitext(latest_file_name_ext)
    print('Reading in file {}'.format(latest_file))
    start_time = time.time()      # START TIMER
    with open(latest_file, "r", newline='') as file:
        df_data = pd.read_csv(file,
                              dtype=str,
                              sep='|',
                              error_bad_lines=False,
                              warn_bad_lines=True,
                              memory_map=True,
                              )
        df_data.columns = df_data.columns.str.strip()         # remove whitespace around column names
        df_data = df_data.astype(str)                         # convert everything to strings
        df_data = df_data.applymap(str.strip)                 # remove whitespace around values
        # df_enifile = df_enifile.replace('', np.nan)         # map nans, to drop NAs rows and columns later
        # df_enifile = df_enifile.dropna(how='all', axis=0)   # remove rows containing only NAs
        # df_enifile = df_enifile.dropna(how='all', axis=1)   # remove columns containing only NAs
        # df_enifile = df_enifile.replace(np.nan, 'NA')       # turbodbc hates null values...
        end_time = time.time()  # END TIMER
        elapsed_time = round(end_time - start_time, 1)
        print("Finished in {} seconds".format(elapsed_time))
        return df_data


def load_table(i, dataframe, repl_or_app, numrows, total_inserted):
    start_splittime = time.time()  # START TIMER
    dataframe.to_sql(dest_tablename,
                     con=engine,
                     schema="stage",
                     if_exists=repl_or_app,
                     index=False,
                     chunksize=numrows,       # Edit here to optimize performance
                     method=None,             # Ensures cursor.executemany() is used
                     )
    gc.collect()
    end_splittime = time.time()  # END TIMER
    elapsed_splittime = end_splittime - start_splittime
    print("{} rows inserted  --  {} of {} lists loaded -- {} seconds."
          .format(dataframe.shape[0],
                  i,
                  len(df_list),
                  round(elapsed_splittime, 1)))
    total_inserted += dataframe.shape[0]
    return total_inserted


#
#   ##### #   # ##### ####     #     ###  #####     #####  ###  #     #####
#   #     #   #   #   #   #   # #   #   #   #       #       #   #     #
#   #      # #    #   #   #  #   #  #       #       #       #   #     #
#   ####    #     #   ####   #   #  #       #       ####    #   #     ####
#   #      # #    #   # #    #####  #       #       #       #   #     #
#   #     #   #   #   #  #   #   #  #   #   #       #       #   #     #
#   ##### #   #   #   #   #  #   #   ###    #       #      ###  ####  #####
#
latest_file, latest_name_ext = unzip_ifdiff("Master_Extract_Data_Mart_*.zip",
                                            "Master_Extract_Data_Mart_*.txt")


#
#   ####   #   #  ###  #    ####        ####   #####
#    #  #  #   #   #   #     #  #        #  #  #
#    #  #  #   #   #   #     #  #        #  #  #
#    ###   #   #   #   #     #  #        #  #  ####
#    #  #  #   #   #   #     #  #        #  #  #
#    #  #  #   #   #   #     #  #        #  #  #
#   ####    ###   ###  #### ####        ####   #
#
df_data                  = read_in_files(latest_file, latest_name_ext)
df_data['Date_Ingested'] = dt.datetime.now()
df_data['FileName']      = latest_name_ext


#
#     ###   ####   #     ###  #####     ####   #####
#    #   #  #   #  #      #     #        #  #  #
#    #      #   #  #      #     #        #  #  #
#     ###   ####   #      #     #        #  #  ####
#        #  #      #      #     #        #  #  #
#    #   #  #      #      #     #        #  #  #
#     ###   #      ####  ###    #       ####   #
#
#
size = 100000  # size of splits
df_list = [df_data[i:i + size] for i in range(0, df_data.shape[0], size)]


#
#    ###  #   #   ###   ####  ####  #####  ###
#     #   #   #  #   #  #     #   #   #   #   #
#     #   ##  #  #      #     #   #   #   #
#     #   # # #   ###   ###   ####    #    ###
#     #   #  ##      #  #     # #     #       #
#     #   #   #  #   #  #     #  #    #   #   #
#    ###  #   #   ###   ####  #   #   #    ###
#
# df_data = df_data.head(100000)
total_rows_to_insert = len(df_data.index)
total_inserted = 0
start_time = time.time()  # START TIMER

for i, df in enumerate(df_list, start=1):
    # Drop/Replace staging table and insert in one step
    if i == 1:
        total_inserted = load_table(i, df, "replace", 1000, total_inserted)
        continue
    else:
        total_inserted = load_table(i, df, "append", 1000, total_inserted)
        continue


end_time = time.time()  # END TIMER
elapsed_time = round(end_time - start_time, 1)

# Get final rowcounts of target table
conn = py.connect(conn_str)
cursor = conn.cursor()
cursor.execute(f"SELECT count(*) FROM {destination_table}")
rowcount_post = cursor.fetchone()
rowcount_post = rowcount_post[0]
cursor.close()
conn.close()

print("MDE's {} INSERTS completed in {} seconds".format(total_inserted, elapsed_time))


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

# sys.exit(0)  # REVIEW:  Delete this line when ready for Prod.
