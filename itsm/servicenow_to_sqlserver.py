#
#       ###   #####  ####   #   #   ###    ###   #####  #   #   ###   #   #
#      #   #  #      #   #  #   #    #    #   #  #      #   #  #   #  #   #
#      #      #      #   #  #   #    #    #      #      ##  #  #   #  #   #
#       ###   ####   ####    # #     #    #      ####   # # #  #   #  # # #
#          #  #      # #     # #     #    #      #      #  ##  #   #  # # #
#      #   #  #      #  #    # #     #    #   #  #      #   #  #   #  ## ##
#       ###   #####  #   #    #     ###    ###   #####  #   #   ###   #   #
#


# from pathlib import Path
from urllib import parse
# import subprocess as sp
# import glob
# import os
import cx_Oracle as ora
import pandas as pd
# import pyodbc as py
import sqlalchemy as sql
import sys
import time
import datetime as dt


# SOURCE CONSTANTS:
QUERY_ORA = """
SELECT  *
FROM SM_DM.SM_INCIDENTS
WHERE 1=1
    AND "ASSIGNMENT" = 'IHR Data Quality Team'
    AND UH_REFERENCE_NUMBER_1 IN ('DSTC',
                                  'DSTP')
"""

# DESTINATION CONSTANTS
DEST_ODBC_DSN       = "{SQL Server Native Client 11.0}"
DESTINATION_SERVER  = "DBVED36880"
DESTINATION_DB      = "IHR_RAP"
DESTINATION_SCHEMA  = "stage"
DEST_TABLENAME      = "Master_Data_Extract_MnR_Latest"
DESTINATION_TABLE   = f"""[{DESTINATION_DB}].[{DESTINATION_SCHEMA}].[{DEST_TABLENAME}]"""
DEST_CONN_STR = f'''\
Driver={DEST_ODBC_DRIVER};\
Server={DESTINATION_SERVER};\
Database={DESTINATION_DB};\
Trusted_Connection=yes;\
'''


def load_table(dataframe, repl_or_app, total_inserted):
    start_splittime = time.time()  # START TIMER
    dataframe.to_sql(DEST_TABLENAME,
                     con=engine,
                     schema="stage",
                     if_exists=repl_or_app,
                     index=False,
                     # chunksize=numrows,       # Edit here to optimize performance
                     method=None,             # Ensures cursor.executemany() is used
                     )
    end_splittime = time.time()  # END TIMER
    elapsed_splittime = end_splittime - start_splittime
    print("{} rows inserted in {} seconds."
          .format(dataframe.shape[0],
                  round(elapsed_splittime, 1)))
    total_inserted += dataframe.shape[0]
    return total_inserted


# Create dataframe from Oracle data:
conn = ora.connect(dsn="UHT_DM")
df_ora = pd.read_sql(QUERY_ORA, con=conn)

# Create SQLAlchemy engine for destination
conn_quoted = parse.quote_plus(DEST_CONN_STR)
engine = sql.create_engine("mssql+pyodbc:///?odbc_connect={}".format(conn_quoted),
                           fast_executemany=True)

#
#    ###  #   #   ###   ####  ####  #####  ###
#     #   #   #  #   #  #     #   #   #   #   #
#     #   ##  #  #      #     #   #   #   #
#     #   # # #   ###   ###   ####    #    ###
#     #   #  ##      #  #     # #     #       #
#     #   #   #  #   #  #     #  #    #   #   #
#    ###  #   #   ###   ####  #   #   #    ###
#
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
