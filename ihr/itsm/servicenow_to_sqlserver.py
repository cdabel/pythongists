"""
 ###   #####  ####   #   #   ###    ###   #####  #   #   ###   #   #
#   #  #      #   #  #   #    #    #   #  #      #   #  #   #  #   #
#      #      #   #  #   #    #    #      #      ##  #  #   #  #   #
 ###   ####   ####    # #     #    #      ####   # # #  #   #  # # #
    #  #      # #     # #     #    #      #      #  ##  #   #  # # #
#   #  #      #  #    # #     #    #   #  #      #   #  #   #  ## ##
 ###   #####  #   #    #     ###    ###   #####  #   #   ###   #   #


ServiceNow incidents worked by the IHR Data Quality Team.
Author:        Chris Dabel
Date Created:  02/03/2020

DESCRIPTION:
      This file takes the data from the "UHT_DM" Oracle Database on the ITM0PR01
      server.
      This Helpdesk presentation explains how to obtain access to and connect to
      this data source:
       - https://helpdesk.uhg.com/At_Your_Service/BSL/BSLtraining/ITSM%20and%20DataMart%20Reporting/presentation.html

         (See items 11 and 12 for instructions on how to request access to the
          database.)

      This script takes incident data from the IHR Data Quality Team's
      incidents and inserts them into the IHR_RAP SQL Server Database table
      called "[IHR_RAP].[stage].[Data_Quality_Incidents]".

      This script authenticates using the CEXP_LOAD service account credentials.
      Authentication happens by way of Oracle wallet configuration, documented
      here:
       - "\\nasv0601\Experience_Reporting\Reporting\Application\Application Files\oracle\README.txt"
"""

from urllib import parse
import cx_Oracle as ora
import pandas as pd
import pyodbc as py
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
DEST_TABLENAME      = "IHR_Incidents"
DESTINATION_TABLE   = f"""[{DESTINATION_DB}].[{DESTINATION_SCHEMA}].[{DEST_TABLENAME}]"""
DEST_CONN_STR = f'''\
Driver={DEST_ODBC_DSN};\
Server={DESTINATION_SERVER};\
Database={DESTINATION_DB};\
Trusted_Connection=yes;\
'''


def load_table(dataframe, repl_or_app):
    dataframe.to_sql(DEST_TABLENAME,
                     con=engine,
                     schema="stage",
                     if_exists=repl_or_app,
                     index=False,
                     method=None,  # Ensures cursor.executemany() is used
                     )
    return dataframe.shape[0]


# Create dataframe from Oracle data:
conn = ora.connect(dsn="UHT_DM")
df_ora = pd.read_sql(QUERY_ORA, con=conn)
df_ora['Date_Ingested'] = dt.datetime.now()

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
# START TIMER
start_time = time.time()
# Drop/Replace staging table and insert in one step
total_inserted = load_table(df_ora, "replace")
# END TIMER
end_time = time.time()
elapsed_time = round(end_time - start_time, 1)

print("{} rows inserted in {} seconds.".format(total_inserted,
                                               round(elapsed_time, 1)))


#
#   #   #    #    #     ###  ####     #   ##### #####
#   #   #   # #   #      #    #  #   # #    #   #
#   #   #  #   #  #      #    #  #  #   #   #   #
#    # #   #   #  #      #    #  #  #   #   #   ####
#    # #   #####  #      #    #  #  #####   #   #
#    # #   #   #  #      #    #  #  #   #   #   #
#     #    #   #  ####  ###  ####   #   #   #   #####
#
# Get count of [stage].[Data_Quality_Incidents]
# Get final rowcounts of target table
conn = py.connect(DEST_CONN_STR)
cursor = conn.cursor()
cursor.execute(f"SELECT count(*) FROM {DESTINATION_TABLE}")
rowcount_post = cursor.fetchone()
rowcount_post = rowcount_post[0]
rowcount_pre  = total_inserted
cursor.close()
conn.close()

row_diff = rowcount_pre - rowcount_post
if (row_diff > 0):
    raise Exception('{} rows failed to insert.'.format(row_diff))

print('Data imported successfully - {} rows failed to insert.\n'
      .format(row_diff))

conn.close()
sys.exit(0)  # REVIEW:  Uncomment this line when ready for Prod
