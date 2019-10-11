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
import pandas as pd
import sys
import pypyodbc as pypy
import time
import datetime as dt


dest_odbc_driver    = "{SQL Server Native Client 11.0}"
destination_server  = "DBVED36880"
destination_db      = "IHR_RAP"
destination_schema  = "stage"
dest_tablename      = "Master_Data_Extract_MnR_Latest"
destination_table   = f"""[{destination_db}].[{destination_schema}].[{dest_tablename}]"""
conn_str = f'''\
Driver={dest_odbc_driver};\
Server={destination_server};\
Database={destination_db};\
Trusted_Connection=yes;\
'''


# Test Source Paths:
SOURCE_PATH         = Path("C:\\Users\\cdabel\\Desktop\\_Temp\\{}")
SOURCE_PATH_STR     = str(SOURCE_PATH.resolve())
CWD_SOURCE_PATH_STR = r'C:/Users/cdabel/Desktop/_Temp'  # (to set CWD of subprocess)

# # Actual Source Paths:
# SOURCE_PATH         = Path("//nasv0403/ihr_prod/Ingest_Storage/MDE/{}")
# SOURCE_PATH_STR     = str(SOURCE_PATH.resolve())
# CWD_SOURCE_PATH_STR = '//nasv0403/ihr_prod/Ingest_Storage/MDE'  # (to set CWD of subprocess)

EXE7ZIP_PATH      = Path("C:\\Program Files\\7-Zip\\7z.exe")
EXE7ZIP_PATH_STR  = str(EXE7ZIP_PATH.resolve())


# Get File
def get_files(search_pattern):
    # global list_files
    list_files = glob.glob(SOURCE_PATH_STR.format(search_pattern))
    latest_file = max(list_files, key=os.path.getctime)
    latest_file_name_ext = os.path.basename(latest_file)
    return latest_file, latest_file_name_ext


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
        df_data = pd.read_csv(file, dtype=str, sep='|')
        df_data.columns = df_data.columns.str.strip()   # remove whitespace around column names
        df_data = df_data.astype(str)
        df_data = df_data.applymap(str.strip)           # remove whitespace around values
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
qdrop = f"""DROP TABLE IF EXISTS {destination_table}"""
# `date_ingested` to be calculated upon ingestion
qcreate = f"""
CREATE TABLE {destination_table}
(
    [RPT_MO_KEY]                  VARCHAR(6)     NULL
  , [MBR_HICN_NUM]                VARCHAR(5)     NULL
  , [MBR_VDS_ID]                  VARCHAR(30)    NULL
  , [MBR_INDV_ID]                 VARCHAR(35)    NULL
  , [MBR_CRD_ID]                  VARCHAR(30)    NULL
  , [MBR_CURR_CMS_CONTR_NUM]      VARCHAR(5)     NULL
  , [MBR_CURR_CMS_PBP_CD]         VARCHAR(3)     NULL
  , [MBR_LST_NM]                  VARCHAR(50)    NULL
  , [MBR_FST_NM]                  VARCHAR(30)    NULL
  , [MBR_MIDL_INIT]               VARCHAR(1)     NULL
  , [MBR_DOB]                     VARCHAR(10)    NULL
  , [MBR_GDR_CD]                  VARCHAR(1)     NULL
  , [MBR_ADR_LN1_TXT]             VARCHAR(50)    NULL
  , [MBR_ADR_LN2_TXT]             VARCHAR(50)    NULL
  , [MBR_ADR_CTY_NM]              VARCHAR(50)    NULL
  , [MBR_ADR_ST_CD]               VARCHAR(2)     NULL
  , [MBR_ADR_ZIP_FULL_CD]         VARCHAR(9)     NULL
  , [MBR_DAY_PH_NUM]              VARCHAR(15)    NULL
  , [MBR_ANNL_CARE_VST_FLG]       BIT            NULL
  , [MBR_ANNL_CARE_VST_DT]        VARCHAR(10)    NULL
  , [MBR_ANNL_CARE_VST_DT_HC]     VARCHAR(10)    NULL
  , [MBR_DIAB_IND]                VARCHAR(1)     NULL
  , [MBR_INCNT_PGM_IND]           VARCHAR(200)   NULL
  , [MBR_TYP_CD]                  VARCHAR(5)     NULL
  , [SRC_SYS]                     VARCHAR(200)   NULL
  , [ASGN_PROV_VDS_ID]            VARCHAR(200)   NULL
  , [ASGN_PROV_MPIN_NUM]          VARCHAR(30)    NULL
  , [ASGN_PROV_NPI_NUM]           VARCHAR(30)    NULL
  , [ASGN_PROV_TIN_NUM]           VARCHAR(30)    NULL
  , [ASGN_PROV_LST_NM]            VARCHAR(60)    NULL
  , [ASGN_PROV_FST_NM]            VARCHAR(64)    NULL
  , [ASGN_PROV_ADR_LN1_TXT]       VARCHAR(50)    NULL
  , [ASGN_PROV_ADR_LN2_TXT]       VARCHAR(50)    NULL
  , [ASGN_PROV_ADR_CTY_NM]        VARCHAR(50)    NULL
  , [ASGN_PROV_ADR_ST_CD]         VARCHAR(2)     NULL
  , [ASGN_PROV_ADR_ZIP_FULL_CD]   VARCHAR(9)     NULL
  , [MSR_1_BCS_RSLT]              VARCHAR(1)     NULL
  , [MSR_2_COL_RSLT]              VARCHAR(1)     NULL
  , [MSR_3_CMCSCR_RSLT]           VARCHAR(1)     NULL
  , [MSR_4_CDCLPP_RSLT]           VARCHAR(1)     NULL
  , [MSR_5_GSO_RSLT]              VARCHAR(1)     NULL
  , [MSR_12_ABA_RSLT]             VARCHAR(1)     NULL
  , [MSR_13_COAMR_RSLT]           VARCHAR(1)     NULL
  , [MSR_14_COAFSA_RSLT]          VARCHAR(1)     NULL
  , [MSR_15_COAPS_RSLT]           VARCHAR(1)     NULL
  , [MSR_16_OMW_RSLT]             VARCHAR(1)     NULL
  , [MSR_16_OMW_DT]               VARCHAR(10)    NULL
  , [MSR_91_OMWX_RSLT]            VARCHAR(1)     NULL
  , [MSR_91_OMWX_DT]              VARCHAR(10)    NULL
  , [MSR_17_CDCEYE_RSLT]          VARCHAR(1)     NULL
  , [MSR_18_CDCNEP_RSLT]          VARCHAR(1)     NULL
  , [MSR_19_CDCA1C9_RSLT]         VARCHAR(1)     NULL
  , [MSR_20_CDC100_RSLT]          VARCHAR(1)     NULL
  , [MSR_21_CBP_RSLT]             TINYINT        NULL
  , [MSR_22_ART_RSLT]             TINYINT        NULL
  , [MSR_49_HRM_PYR_RSLT]         VARCHAR(1)     NULL
  , [MSR_49_HRM_CYR_STS]          VARCHAR(1)     NULL
  , [MSR_49_HRM_CYR_RSLT]         VARCHAR(1)     NULL
  , [MSR_51_MAD_PYR_RSLT]         VARCHAR(1)     NULL
  , [MSR_51_MAD_CYR_STS]          VARCHAR(1)     NULL
  , [MSR_51_MAD_CYR_RSLT]         TINYINT        NULL
  , [MSR_51_MAD_CURR_PDC]         VARCHAR(10)    NULL
  , [MSR_51_MAD_FA_CYR_RSLT]      TINYINT        NULL
  , [MSR_51_MAD_AD]               SMALLINT       NULL
  , [MSR_51_MAD_DM45]             SMALLINT       NULL
  , [MSR_51_MAD_EOY_PDC_PRED]     VARCHAR(10)    NULL
  , [MSR_52_MAH_PYR_RSLT]         VARCHAR(1)     NULL
  , [MSR_52_MAH_CYR_STS]          VARCHAR(1)     NULL
  , [MSR_52_MAH_CYR_RSLT]         TINYINT        NULL
  , [MSR_52_MAH_CURR_PDC]         VARCHAR(10)    NULL
  , [MSR_52_MAH_FA_CYR_RSLT]      TINYINT        NULL
  , [MSR_52_MAH_AD]               SMALLINT       NULL
  , [MSR_52_MAH_DM45]             SMALLINT       NULL
  , [MSR_52_MAH_EOY_PDC_PRED]     VARCHAR(10)    NULL
  , [MSR_53_MAC_PYR_RSLT]         VARCHAR(1)     NULL
  , [MSR_53_MAC_CYR_STS]          VARCHAR(1)     NULL
  , [MSR_53_MAC_CYR_RSLT]         TINYINT        NULL
  , [MSR_53_MAC_CURR_PDC]         VARCHAR(10)    NULL
  , [MSR_53_MAC_FA_CYR_RSLT]      TINYINT        NULL
  , [MSR_53_MAC_AD]               SMALLINT       NULL
  , [MSR_53_MAC_DM45]             SMALLINT       NULL
  , [MSR_53_MAC_EOY_PDC_PRED]     VARCHAR(10)    NULL
  , [MSR_100_SUPD_PYR_RSLT]       VARCHAR(1)     NULL
  , [MSR_100_SUPD_CYR_STS]        VARCHAR(1)     NULL
  , [MSR_100_SUPD_CYR_RSLT]       VARCHAR(1)     NULL
  , [MSR_101_SPC_RSLT]            VARCHAR(1)     NULL
  , [MSR_58_FMI_RSLT]             VARCHAR(1)     NULL
  , [MSR_60_AMM_RSLT]             VARCHAR(1)     NULL
  , [MSR_61_BBT_RSLT]             VARCHAR(1)     NULL
  , [MSR_62_MPLM_RSLT]            VARCHAR(1)     NULL
  , [MSR_64_COPD_RSLT]            VARCHAR(1)     NULL
  , [MSR_71_PCE_SC_RSLT]          VARCHAR(1)     NULL
  , [MSR_72_PCEBRON_RSLT]         VARCHAR(1)     NULL
  , [MSR_73_AODRINITOT_RSLT]      VARCHAR(1)     NULL
  , [MSR_74_EADT_RSLT]            VARCHAR(1)     NULL
  , [ASSOC_PROV_VDS_ID]           VARCHAR(200)   NULL
  , [ASSOC_PROV_MPIN_NUM]         VARCHAR(30)    NULL
  , [ASSOC_PROV_NPI_NUM]          VARCHAR(30)    NULL
  , [ASSOC_PROV_TIN]              VARCHAR(30)    NULL
  , [ASSOC_PROV_LST_NM]           VARCHAR(60)    NULL
  , [ASSOC_PROV_FST_NM]           VARCHAR(64)    NULL
  , [ASSOC_PROV_ADR_LN1_TXT]      VARCHAR(50)    NULL
  , [ASSOC_PROV_ADR_LN2_TXT]      VARCHAR(50)    NULL
  , [ASSOC_PROV_ADR_CTY_NM]       VARCHAR(50)    NULL
  , [ASSOC_PROV_ADR_ST_CD]        VARCHAR(2)     NULL
  , [ASSOC_PROV_ADR_ZIP_FULL_CD]  VARCHAR(9)     NULL
  , [ASSOC_PROV_ASGN_RNDR_IND]    VARCHAR(1)     NULL
  , [ASSOC_PROV_GRP_TYP_CD]       VARCHAR(30)    NULL
  , [ASSOC_PROV_GRP_ID]           VARCHAR(200)   NULL
  , [ASSOC_PROV_GRP_NM]           VARCHAR(255)   NULL
  , [ASSOC_HLTH_SYS_ID]           VARCHAR(255)   NULL
  , [ASSOC_HLTH_SYS_NM]           VARCHAR(255)   NULL
  , [ROW_INSRT_DT]                VARCHAR(30)    NULL
  , [LST_HICN_BFR_MBI]            VARCHAR(30)    NULL
  , [SegmentID]                   TINYINT        NULL
  , [MSR_RSLT_86]                 BIT            NULL
  , [PARTD_ALRT_LVL_86]           VARCHAR(1)     NULL
  , [MSR_RSLT_CY_86]              BIT            NULL
)
;
"""


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
#   ####   #   #  ###  #     ####       ###  #   #   ###  ##### ####  #####
#    #  #  #   #   #   #      #  #       #   #   #  #   # #     #   #   #
#    #  #  #   #   #   #      #  #       #   ##  #  #     #     #   #   #
#    ###   #   #   #   #      #  #       #   # # #   ###  ####  ####    #
#    #  #  #   #   #   #      #  #       #   #  ##      # #     # #     #
#    #  #  #   #   #   #      #  #       #   #   #  #   # #     #  #    #
#   ####    ###   ###  ##### ####       ###  #   #   ###  ##### #   #   #
#
cols_to_update, rows_list = read_in_files(latest_file, latest_name_ext)
cols_to_update.append("date_ingested")
cols_to_update.append("FileName")


# Generate series of parameters for INSERT statements
param_builder = "?"
for i in range(len(cols_to_update) - 1):  # minus 1 since it initialized with 1
    param_builder += ", ?"


# Build INSERT statements
strofcols = ",\n  ".join(cols_to_update)  # print(strofcols)
qinsert = f"""
INSERT INTO {destination_table}
( {strofcols} )
VALUES ( {param_builder} )
"""  # print(qinsert)


#
#    ####   ####    #
#     #  #   #  #   #
#     #  #   #  #   #
#     #  #   #  #   #
#     #  #   #  #   #
#     #  #   #  #   #
#    ####   ####    #####
#
# Open connection/cursor
conn = pypy.connect(conn_str)
cursor = conn.cursor()


# Prep staging tables
runquery(qdrop)    # drop stage table if it exists (supported on SQL Server 2016+)
runquery(qcreate)  # create staging table
conn.commit()


# Check existing rowcounts of target tables
cursor.execute(f"SELECT count(*) FROM {destination_table}")
rowcount_pre = cursor.fetchone()
rowcount_pre = rowcount_pre[0]


#
#   ####   #   #   #            ###  #   #   ###   #### ####  #####  ###
#    #  #  #   #   #             #   #   #  #   #  #    #   #   #   #   #
#    #  #  ## ##   #             #   ##  #  #      #    #   #   #   #
#    #  #  # # #   #     ####    #   # # #   ###   ###  ####    #    ###
#    #  #  #   #   #             #   #  ##      #  #    # #     #       #
#    #  #  #   #   #             #   #   #  #   #  #    #  #    #   #   #
#   ####   #   #   ####         ###  #   #   ###   #### #   #   #    ###
#
total_rows_to_insert = 20  # len(rows_list)
start_time = time.time()  # START TIMER

rows_to_insert = []
rows_to_insert.clear()
run_insert_query(rowcount_pre,
                 rows_list,
                 latest_name_ext,
                 qinsert,
                 "Master_Data_Extract",
                 total_rows_to_insert)
conn.commit()

end_time = time.time()  # END TIMER
elapsed_time = str(round(end_time - start_time, 1))
print("MDE's {} INSERTS Completed in {} seconds".format(total_rows_to_insert, elapsed_time))

# Get final rowcounts of target table
cursor.execute(f"SELECT count(*) FROM {destination_table}")
rowcount_post = cursor.fetchone()
rowcount_post = rowcount_post[0]


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
