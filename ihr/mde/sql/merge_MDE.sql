SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

---- ==========================================================================================
---- ==========================================================================================
---- Author:             Chris Dabel
---- Create date:        9/20/2019
---- Description:        Merge members from most recent Master Data Extract (MDE), as seen in
----                     staging table [IHR_RAP].[stage].[Master_Data_Extract_MnR_Latest]  
----                     to [IHR_RAP].[Member].[MnR_Master]
---- Store Proc Name:    merge_mde_sp
----                     * How to call this SP from APVEP32146 server connection:
----                       - EXEC [DBVED36880].IHR_RAP.dbo.merge_mde_sp;
---- ==========================================================================================
---- ==========================================================================================


USE IHR_RAP;
GO

CREATE PROCEDURE [dbo].[merge_mde_sp]
AS
WITH
  cte_source AS
(
SELECT 
  CONVERT( VARCHAR(12),   MBR_HICN_NUM )                    AS MBR_HICN_NUM
, CONVERT( INT,           RPT_MO_KEY )                      AS RPT_MO_KEY
, CONVERT( VARCHAR(25),   MBR_VDS_ID )                      AS MBR_VDS_ID
, CONVERT( INT,           MBR_INDV_ID )                     AS MBR_INDV_ID
, CONVERT( VARCHAR(15),   CONVERT( INT, MBR_INDV_ID ))      AS MBR_INDV_ID_STR
, CONVERT( VARCHAR(30),   MBR_CRD_ID )                      AS MBR_CRD_ID
, CONVERT( VARCHAR(5),    MBR_CURR_CMS_CONTR_NUM )          AS MBR_CURR_CMS_CONTR_NUM
, CONVERT( VARCHAR(3),    MBR_CURR_CMS_PBP_CD )             AS MBR_CURR_CMS_PBP_CD
, CONVERT( VARCHAR(255),  MBR_LST_NM )                      AS MBR_LST_NM
, CONVERT( VARCHAR(255),  MBR_FST_NM )                      AS MBR_FST_NM
, CONVERT( VARCHAR(1),    MBR_MIDL_INIT )                   AS MBR_MIDL_INIT
, CONVERT( DATE, CASE 
                   WHEN MBR_DOB = '' THEN NULL 
                   ELSE MBR_DOB 
                 END )                                      AS MBR_DOB
, CONVERT( VARCHAR(1),    MBR_GDR_CD )                      AS MBR_GDR_CD
, CONVERT( VARCHAR(100),  MBR_ADR_LN1_TXT )                 AS MBR_ADR_LN1_TXT
, CONVERT( VARCHAR(100),  MBR_ADR_LN2_TXT )                 AS MBR_ADR_LN2_TXT
, CONVERT( VARCHAR(50),   MBR_ADR_CTY_NM )                  AS MBR_ADR_CTY_NM
, CONVERT( VARCHAR(2),    MBR_ADR_ST_CD )                   AS MBR_ADR_ST_CD
, CONVERT( VARCHAR(10), REPLACE( CASE 
                                   WHEN MBR_ADR_ZIP_FULL_CD = ''
                                   THEN NULL 
                                   ELSE MBR_ADR_ZIP_FULL_CD
                                 END, '-', '' ))            AS MBR_ADR_ZIP_FULL_CD -- varchar(max)
, CONVERT( VARCHAR(15),   MBR_DAY_PH_NUM )                  AS MBR_DAY_PH_NUM
, CAST( MBR_ANNL_CARE_VST_FLG AS BIT )                      AS MBR_ANNL_CARE_VST_FLG
, CONVERT( DATE, CASE 
                   WHEN MBR_ANNL_CARE_VST_DT = '' 
                   THEN NULL 
                   ELSE MBR_ANNL_CARE_VST_DT 
                 END )                                      AS MBR_ANNL_CARE_VST_DT
, CONVERT( DATE, CASE 
                   WHEN MBR_ANNL_CARE_VST_DT_HC = '' 
                   THEN NULL 
                   ELSE MBR_ANNL_CARE_VST_DT_HC 
                 END  )                                     AS MBR_ANNL_CARE_VST_DT_HC
, CAST( MBR_DIAB_IND AS BIT )                               AS MBR_DIAB_IND
, CONVERT( VARCHAR(25),   MBR_INCNT_PGM_IND )               AS MBR_INCNT_PGM_IND
, CONVERT( VARCHAR(5),    MBR_TYP_CD )                      AS MBR_TYP_CD
, CONVERT( VARCHAR(25),   SRC_SYS )                         AS SRC_SYS
, CONVERT( VARCHAR(25),   ASGN_PROV_VDS_ID )                AS ASGN_PROV_VDS_ID
, TRY_CONVERT( INT,       ASGN_PROV_MPIN_NUM )              AS ASGN_PROV_MPIN_NUM
, TRY_CONVERT( BIGINT,    ASGN_PROV_NPI_NUM )               AS ASGN_PROV_NPI_NUM
, TRY_CONVERT( INT,       ASGN_PROV_TIN_NUM )               AS ASGN_PROV_TIN_NUM
, CONVERT( VARCHAR(75),   ASGN_PROV_LST_NM )                AS ASGN_PROV_LST_NM
, CONVERT( VARCHAR(75),   ASGN_PROV_FST_NM )                AS ASGN_PROV_FST_NM
, CONVERT( VARCHAR(100),  ASGN_PROV_ADR_LN1_TXT )           AS ASGN_PROV_ADR_LN1_TXT
, CONVERT( VARCHAR(100),  ASGN_PROV_ADR_LN2_TXT )           AS ASGN_PROV_ADR_LN2_TXT
, CONVERT( VARCHAR(50),   ASGN_PROV_ADR_CTY_NM )            AS ASGN_PROV_ADR_CTY_NM
, CONVERT( VARCHAR(2),    ASGN_PROV_ADR_ST_CD )             AS ASGN_PROV_ADR_ST_CD
, CONVERT( VARCHAR(10),   CONVERT(DECIMAL(20), ASGN_PROV_ADR_ZIP_FULL_CD ))  AS ASGN_PROV_ADR_ZIP_FULL_CD -- float
, CAST( MSR_1_BCS_RSLT      AS BIT )                        AS MSR_1_BCS_RSLT
, CAST( MSR_2_COL_RSLT      AS BIT )                        AS MSR_2_COL_RSLT
, CAST( MSR_3_CMCSCR_RSLT   AS BIT )                        AS MSR_3_CMCSCR_RSLT
, CAST( MSR_4_CDCLPP_RSLT   AS BIT )                        AS MSR_4_CDCLPP_RSLT
, CAST( MSR_5_GSO_RSLT      AS BIT )                        AS MSR_5_GSO_RSLT
, CAST( MSR_12_ABA_RSLT     AS BIT )                        AS MSR_12_ABA_RSLT
, CAST( MSR_13_COAMR_RSLT   AS BIT )                        AS MSR_13_COAMR_RSLT
, CAST( MSR_14_COAFSA_RSLT  AS BIT )                        AS MSR_14_COAFSA_RSLT
, CAST( MSR_15_COAPS_RSLT   AS BIT )                        AS MSR_15_COAPS_RSLT
, CAST( MSR_16_OMW_RSLT     AS BIT )                        AS MSR_16_OMW_RSLT
, CONVERT( DATE, CASE
                   WHEN MSR_16_OMW_DT = ''
                   THEN NULL 
                   ELSE MSR_16_OMW_DT
                 END )                                      AS MSR_16_OMW_DT
, CAST( MSR_91_OMWX_RSLT    AS BIT )                        AS MSR_91_OMWX_RSLT
, CONVERT( DATE, CASE
                   WHEN MSR_91_OMWX_DT = ''
                   THEN NULL
                   ELSE MSR_91_OMWX_DT
                 END )                                      AS MSR_91_OMWX_DT
, CAST( MSR_17_CDCEYE_RSLT  AS BIT )                        AS MSR_17_CDCEYE_RSLT
, CAST( MSR_18_CDCNEP_RSLT  AS BIT )                        AS MSR_18_CDCNEP_RSLT
, CAST( MSR_19_CDCA1C9_RSLT AS BIT )                        AS MSR_19_CDCA1C9_RSLT
, CAST( MSR_20_CDC100_RSLT  AS BIT )                        AS MSR_20_CDC100_RSLT
, CONVERT( TINYINT,       MSR_21_CBP_RSLT )                 AS MSR_21_CBP_RSLT
, CONVERT( TINYINT,       MSR_22_ART_RSLT )                 AS MSR_22_ART_RSLT
, CAST( MSR_49_HRM_PYR_RSLT AS BIT )                        AS MSR_49_HRM_PYR_RSLT
, CONVERT( VARCHAR(1),    MSR_49_HRM_CYR_STS )              AS MSR_49_HRM_CYR_STS
, CAST( MSR_49_HRM_CYR_RSLT AS BIT )                        AS MSR_49_HRM_CYR_RSLT
, CAST( MSR_51_MAD_PYR_RSLT AS BIT )                        AS MSR_51_MAD_PYR_RSLT
, CONVERT( VARCHAR(1),    MSR_51_MAD_CYR_STS )              AS MSR_51_MAD_CYR_STS
, CONVERT( TINYINT,       MSR_51_MAD_CYR_RSLT )             AS MSR_51_MAD_CYR_RSLT
, CONVERT( DECIMAL(3,2),  MSR_51_MAD_CURR_PDC )             AS MSR_51_MAD_CURR_PDC
, CONVERT( TINYINT,       MSR_51_MAD_FA_CYR_RSLT )          AS MSR_51_MAD_FA_CYR_RSLT
, CONVERT( SMALLINT,      MSR_51_MAD_AD )                   AS MSR_51_MAD_AD
, CONVERT( SMALLINT,      MSR_51_MAD_DM45 )                 AS MSR_51_MAD_DM45
, CONVERT( DECIMAL(3,2),  MSR_51_MAD_EOY_PDC_PRED )         AS MSR_51_MAD_EOY_PDC_PRED
, CAST( MSR_52_MAH_PYR_RSLT AS BIT )                        AS MSR_52_MAH_PYR_RSLT
, CONVERT( VARCHAR(1),    MSR_52_MAH_CYR_STS )              AS MSR_52_MAH_CYR_STS
, CONVERT( TINYINT,       MSR_52_MAH_CYR_RSLT )             AS MSR_52_MAH_CYR_RSLT
, CONVERT( DECIMAL(3,2),  MSR_52_MAH_CURR_PDC )             AS MSR_52_MAH_CURR_PDC
, CONVERT( TINYINT,       MSR_52_MAH_FA_CYR_RSLT )          AS MSR_52_MAH_FA_CYR_RSLT
, CONVERT( SMALLINT,      MSR_52_MAH_AD )                   AS MSR_52_MAH_AD
, CONVERT( SMALLINT,      MSR_52_MAH_DM45 )                 AS MSR_52_MAH_DM45
, CONVERT( DECIMAL(3,2),  MSR_52_MAH_EOY_PDC_PRED )         AS MSR_52_MAH_EOY_PDC_PRED
, CAST( MSR_53_MAC_PYR_RSLT AS BIT )                        AS MSR_53_MAC_PYR_RSLT
, CONVERT( VARCHAR(1),    MSR_53_MAC_CYR_STS )              AS MSR_53_MAC_CYR_STS
, CONVERT( TINYINT,       MSR_53_MAC_CYR_RSLT )             AS MSR_53_MAC_CYR_RSLT
, CONVERT( DECIMAL(3,2),  MSR_53_MAC_CURR_PDC )             AS MSR_53_MAC_CURR_PDC
, CONVERT( TINYINT,       MSR_53_MAC_FA_CYR_RSLT )          AS MSR_53_MAC_FA_CYR_RSLT
, CONVERT( SMALLINT,      MSR_53_MAC_AD )                   AS MSR_53_MAC_AD
, CONVERT( SMALLINT,      MSR_53_MAC_DM45 )                 AS MSR_53_MAC_DM45
, CONVERT( DECIMAL(3,2),  MSR_53_MAC_EOY_PDC_PRED )         AS MSR_53_MAC_EOY_PDC_PRED
, CAST( MSR_100_SUPD_PYR_RSLT  AS BIT )                     AS MSR_100_SUPD_PYR_RSLT
, CONVERT( VARCHAR(1),    MSR_100_SUPD_CYR_STS )            AS MSR_100_SUPD_CYR_STS
, CAST( MSR_100_SUPD_CYR_RSLT  AS BIT )                     AS MSR_100_SUPD_CYR_RSLT
, CAST( MSR_101_SPC_RSLT       AS BIT )                     AS MSR_101_SPC_RSLT
, CAST( MSR_58_FMI_RSLT        AS BIT )                     AS MSR_58_FMI_RSLT
, CAST( MSR_60_AMM_RSLT        AS BIT )                     AS MSR_60_AMM_RSLT
, CAST( MSR_61_BBT_RSLT        AS BIT )                     AS MSR_61_BBT_RSLT
, CAST( MSR_62_MPLM_RSLT       AS BIT )                     AS MSR_62_MPLM_RSLT
, CAST( MSR_64_COPD_RSLT       AS BIT )                     AS MSR_64_COPD_RSLT
, CAST( MSR_71_PCE_SC_RSLT     AS BIT )                     AS MSR_71_PCE_SC_RSLT
, CAST( MSR_72_PCEBRON_RSLT    AS BIT )                     AS MSR_72_PCEBRON_RSLT
, CAST( MSR_73_AODRINITOT_RSLT AS BIT )                     AS MSR_73_AODRINITOT_RSLT
, CAST( MSR_74_EADT_RSLT       AS BIT )                     AS MSR_74_EADT_RSLT
, CONVERT( VARCHAR(25),   ASSOC_PROV_VDS_ID )               AS ASSOC_PROV_VDS_ID
, TRY_CONVERT( INT,       ASSOC_PROV_MPIN_NUM )             AS ASSOC_PROV_MPIN_NUM
, TRY_CONVERT( BIGINT,    ASSOC_PROV_NPI_NUM )              AS ASSOC_PROV_NPI_NUM
, TRY_CONVERT( INT,       ASSOC_PROV_TIN )                  AS ASSOC_PROV_TIN
, CONVERT( VARCHAR(75),   ASSOC_PROV_LST_NM )               AS ASSOC_PROV_LST_NM
, CONVERT( VARCHAR(75),   ASSOC_PROV_FST_NM )               AS ASSOC_PROV_FST_NM
, CONVERT( VARCHAR(100),  ASSOC_PROV_ADR_LN1_TXT )          AS ASSOC_PROV_ADR_LN1_TXT
, CONVERT( VARCHAR(100),  ASSOC_PROV_ADR_LN2_TXT )          AS ASSOC_PROV_ADR_LN2_TXT
, CONVERT( VARCHAR(50),   ASSOC_PROV_ADR_CTY_NM )           AS ASSOC_PROV_ADR_CTY_NM
, CONVERT( VARCHAR(2),    ASSOC_PROV_ADR_ST_CD )            AS ASSOC_PROV_ADR_ST_CD
, CONVERT( VARCHAR(10),   REPLACE( CASE
                                     WHEN ASSOC_PROV_ADR_ZIP_FULL_CD = ''
                                     THEN NULL 
                                     ELSE ASSOC_PROV_ADR_ZIP_FULL_CD  
                                   END, '-', '' ))          AS ASSOC_PROV_ADR_ZIP_FULL_CD --varchar(max)
, CONVERT( VARCHAR(1),    ASSOC_PROV_ASGN_RNDR_IND )        AS ASSOC_PROV_ASGN_RNDR_IND
, CONVERT( VARCHAR(30),   ASSOC_PROV_GRP_TYP_CD )           AS ASSOC_PROV_GRP_TYP_CD
, CONVERT( VARCHAR(200),  ASSOC_PROV_GRP_ID )               AS ASSOC_PROV_GRP_ID
, CONVERT( VARCHAR(255),  ASSOC_PROV_GRP_NM )               AS ASSOC_PROV_GRP_NM
, CONVERT( VARCHAR(255),  ASSOC_HLTH_SYS_ID )               AS ASSOC_HLTH_SYS_ID
, CONVERT( VARCHAR(255),  ASSOC_HLTH_SYS_NM )               AS ASSOC_HLTH_SYS_NM
, CONVERT( VARCHAR(19),   ROW_INSRT_DT, 120 )               AS ROW_INSRT_DT
, CONVERT( VARCHAR(15),   LST_HICN_BFR_MBI )                AS LST_HICN_BFR_MBI
, CONVERT( TINYINT,       SegmentID )                       AS SegmentID
, CAST( MSR_RSLT_86    AS BIT )                             AS MSR_RSLT_86
, CONVERT( VARCHAR(1),    PARTD_ALRT_LVL_86 )               AS PARTD_ALRT_LVL_86
, CAST( MSR_RSLT_CY_86 AS BIT )                             AS MSR_RSLT_CY_86
, CONVERT(VARCHAR(19),    Date_Ingested, 120)               AS Load_Date_Py
, 1                                                         AS CountOfFiles
, CONVERT( VARCHAR(255),  FileName )                        AS FileName
FROM [IHR_RAP].[stage].[Master_Data_Extract_MnR_Latest]
)
/*
     #   #  ####  ####    ###   ####
     #   #  #     #   #  #   #  #
     ## ##  #     #   #  #      #
     # # #  ###   ####   #      ###
     #   #  #     # #    #  ##  #
     #   #  #     #  #   #   #  #
     #   #  ####  #   #   ###   ####
 */
MERGE [IHR_RAP].[Member].[MnR_Master_Data_Extract]  AS target
USING cte_source                                    AS source
   ON ( source.MBR_HICN_NUM = target.[MBR_HICN_NUM] )
WHEN NOT MATCHED 
THEN INSERT (  MBR_HICN_NUM
             , RPT_MO_KEY
             , MBR_VDS_ID
             , MBR_INDV_ID
             , MBR_INDV_ID_STR
             , MBR_CRD_ID
             , MBR_CURR_CMS_CONTR_NUM
             , MBR_CURR_CMS_PBP_CD
             , MBR_LST_NM
             , MBR_FST_NM
             , MBR_MIDL_INIT
             , MBR_DOB
             , MBR_GDR_CD
             , MBR_ADR_LN1_TXT
             , MBR_ADR_LN2_TXT
             , MBR_ADR_CTY_NM
             , MBR_ADR_ST_CD
             , MBR_ADR_ZIP_FULL_CD
             , MBR_DAY_PH_NUM
             , MBR_ANNL_CARE_VST_FLG
             , MBR_ANNL_CARE_VST_DT
             , MBR_ANNL_CARE_VST_DT_HC
             , MBR_DIAB_IND
             , MBR_INCNT_PGM_IND
             , MBR_TYP_CD
             , SRC_SYS
             , ASGN_PROV_VDS_ID
             , ASGN_PROV_MPIN_NUM
             , ASGN_PROV_NPI_NUM
             , ASGN_PROV_TIN_NUM
             , ASGN_PROV_LST_NM
             , ASGN_PROV_FST_NM
             , ASGN_PROV_ADR_LN1_TXT
             , ASGN_PROV_ADR_LN2_TXT
             , ASGN_PROV_ADR_CTY_NM
             , ASGN_PROV_ADR_ST_CD
             , ASGN_PROV_ADR_ZIP_FULL_CD
             , MSR_1_BCS_RSLT
             , MSR_2_COL_RSLT
             , MSR_3_CMCSCR_RSLT
             , MSR_4_CDCLPP_RSLT
             , MSR_5_GSO_RSLT
             , MSR_12_ABA_RSLT
             , MSR_13_COAMR_RSLT
             , MSR_14_COAFSA_RSLT
             , MSR_15_COAPS_RSLT
             , MSR_16_OMW_RSLT
             , MSR_16_OMW_DT
             , MSR_91_OMWX_RSLT
             , MSR_91_OMWX_DT
             , MSR_17_CDCEYE_RSLT
             , MSR_18_CDCNEP_RSLT
             , MSR_19_CDCA1C9_RSLT
             , MSR_20_CDC100_RSLT
             , MSR_21_CBP_RSLT
             , MSR_22_ART_RSLT
             , MSR_49_HRM_PYR_RSLT
             , MSR_49_HRM_CYR_STS
             , MSR_49_HRM_CYR_RSLT
             , MSR_51_MAD_PYR_RSLT
             , MSR_51_MAD_CYR_STS
             , MSR_51_MAD_CYR_RSLT
             , MSR_51_MAD_CURR_PDC
             , MSR_51_MAD_FA_CYR_RSLT
             , MSR_51_MAD_AD
             , MSR_51_MAD_DM45
             , MSR_51_MAD_EOY_PDC_PRED
             , MSR_52_MAH_PYR_RSLT
             , MSR_52_MAH_CYR_STS
             , MSR_52_MAH_CYR_RSLT
             , MSR_52_MAH_CURR_PDC
             , MSR_52_MAH_FA_CYR_RSLT
             , MSR_52_MAH_AD
             , MSR_52_MAH_DM45
             , MSR_52_MAH_EOY_PDC_PRED
             , MSR_53_MAC_PYR_RSLT
             , MSR_53_MAC_CYR_STS
             , MSR_53_MAC_CYR_RSLT
             , MSR_53_MAC_CURR_PDC
             , MSR_53_MAC_FA_CYR_RSLT
             , MSR_53_MAC_AD
             , MSR_53_MAC_DM45
             , MSR_53_MAC_EOY_PDC_PRED
             , MSR_100_SUPD_PYR_RSLT
             , MSR_100_SUPD_CYR_STS
             , MSR_100_SUPD_CYR_RSLT
             , MSR_101_SPC_RSLT
             , MSR_58_FMI_RSLT
             , MSR_60_AMM_RSLT
             , MSR_61_BBT_RSLT
             , MSR_62_MPLM_RSLT
             , MSR_64_COPD_RSLT
             , MSR_71_PCE_SC_RSLT
             , MSR_72_PCEBRON_RSLT
             , MSR_73_AODRINITOT_RSLT
             , MSR_74_EADT_RSLT
             , ASSOC_PROV_VDS_ID
             , ASSOC_PROV_MPIN_NUM
             , ASSOC_PROV_NPI_NUM
             , ASSOC_PROV_TIN
             , ASSOC_PROV_LST_NM
             , ASSOC_PROV_FST_NM
             , ASSOC_PROV_ADR_LN1_TXT
             , ASSOC_PROV_ADR_LN2_TXT
             , ASSOC_PROV_ADR_CTY_NM
             , ASSOC_PROV_ADR_ST_CD
             , ASSOC_PROV_ADR_ZIP_FULL_CD
             , ASSOC_PROV_ASGN_RNDR_IND
             , ASSOC_PROV_GRP_TYP_CD
             , ASSOC_PROV_GRP_ID
             , ASSOC_PROV_GRP_NM
             , ASSOC_HLTH_SYS_ID
             , ASSOC_HLTH_SYS_NM
             , ROW_INSRT_DT
             , LST_HICN_BFR_MBI
             , SegmentID
             , MSR_RSLT_86
             , PARTD_ALRT_LVL_86
             , MSR_RSLT_CY_86
             , Load_Date_Py
             , CountOfFiles
             , FileName
             , InsertDate
             , MnR_Status
             , MnR_SubStatus
            )
     VALUES (  source.MBR_HICN_NUM
             , source.RPT_MO_KEY
             , source.MBR_VDS_ID
             , source.MBR_INDV_ID
             , source.MBR_INDV_ID_STR
             , source.MBR_CRD_ID
             , source.MBR_CURR_CMS_CONTR_NUM
             , source.MBR_CURR_CMS_PBP_CD
             , source.MBR_LST_NM
             , source.MBR_FST_NM
             , source.MBR_MIDL_INIT
             , source.MBR_DOB
             , source.MBR_GDR_CD
             , source.MBR_ADR_LN1_TXT
             , source.MBR_ADR_LN2_TXT
             , source.MBR_ADR_CTY_NM
             , source.MBR_ADR_ST_CD
             , source.MBR_ADR_ZIP_FULL_CD
             , source.MBR_DAY_PH_NUM
             , source.MBR_ANNL_CARE_VST_FLG
             , source.MBR_ANNL_CARE_VST_DT
             , source.MBR_ANNL_CARE_VST_DT_HC
             , source.MBR_DIAB_IND
             , source.MBR_INCNT_PGM_IND
             , source.MBR_TYP_CD
             , source.SRC_SYS
             , source.ASGN_PROV_VDS_ID
             , source.ASGN_PROV_MPIN_NUM
             , source.ASGN_PROV_NPI_NUM
             , source.ASGN_PROV_TIN_NUM
             , source.ASGN_PROV_LST_NM
             , source.ASGN_PROV_FST_NM
             , source.ASGN_PROV_ADR_LN1_TXT
             , source.ASGN_PROV_ADR_LN2_TXT
             , source.ASGN_PROV_ADR_CTY_NM
             , source.ASGN_PROV_ADR_ST_CD
             , source.ASGN_PROV_ADR_ZIP_FULL_CD
             , source.MSR_1_BCS_RSLT
             , source.MSR_2_COL_RSLT
             , source.MSR_3_CMCSCR_RSLT
             , source.MSR_4_CDCLPP_RSLT
             , source.MSR_5_GSO_RSLT
             , source.MSR_12_ABA_RSLT
             , source.MSR_13_COAMR_RSLT
             , source.MSR_14_COAFSA_RSLT
             , source.MSR_15_COAPS_RSLT
             , source.MSR_16_OMW_RSLT
             , source.MSR_16_OMW_DT
             , source.MSR_91_OMWX_RSLT
             , source.MSR_91_OMWX_DT
             , source.MSR_17_CDCEYE_RSLT
             , source.MSR_18_CDCNEP_RSLT
             , source.MSR_19_CDCA1C9_RSLT
             , source.MSR_20_CDC100_RSLT
             , source.MSR_21_CBP_RSLT
             , source.MSR_22_ART_RSLT
             , source.MSR_49_HRM_PYR_RSLT
             , source.MSR_49_HRM_CYR_STS
             , source.MSR_49_HRM_CYR_RSLT
             , source.MSR_51_MAD_PYR_RSLT
             , source.MSR_51_MAD_CYR_STS
             , source.MSR_51_MAD_CYR_RSLT
             , source.MSR_51_MAD_CURR_PDC
             , source.MSR_51_MAD_FA_CYR_RSLT
             , source.MSR_51_MAD_AD
             , source.MSR_51_MAD_DM45
             , source.MSR_51_MAD_EOY_PDC_PRED
             , source.MSR_52_MAH_PYR_RSLT
             , source.MSR_52_MAH_CYR_STS
             , source.MSR_52_MAH_CYR_RSLT
             , source.MSR_52_MAH_CURR_PDC
             , source.MSR_52_MAH_FA_CYR_RSLT
             , source.MSR_52_MAH_AD
             , source.MSR_52_MAH_DM45
             , source.MSR_52_MAH_EOY_PDC_PRED
             , source.MSR_53_MAC_PYR_RSLT
             , source.MSR_53_MAC_CYR_STS
             , source.MSR_53_MAC_CYR_RSLT
             , source.MSR_53_MAC_CURR_PDC
             , source.MSR_53_MAC_FA_CYR_RSLT
             , source.MSR_53_MAC_AD
             , source.MSR_53_MAC_DM45
             , source.MSR_53_MAC_EOY_PDC_PRED
             , source.MSR_100_SUPD_PYR_RSLT
             , source.MSR_100_SUPD_CYR_STS
             , source.MSR_100_SUPD_CYR_RSLT
             , source.MSR_101_SPC_RSLT
             , source.MSR_58_FMI_RSLT
             , source.MSR_60_AMM_RSLT
             , source.MSR_61_BBT_RSLT
             , source.MSR_62_MPLM_RSLT
             , source.MSR_64_COPD_RSLT
             , source.MSR_71_PCE_SC_RSLT
             , source.MSR_72_PCEBRON_RSLT
             , source.MSR_73_AODRINITOT_RSLT
             , source.MSR_74_EADT_RSLT
             , source.ASSOC_PROV_VDS_ID
             , source.ASSOC_PROV_MPIN_NUM
             , source.ASSOC_PROV_NPI_NUM
             , source.ASSOC_PROV_TIN
             , source.ASSOC_PROV_LST_NM
             , source.ASSOC_PROV_FST_NM
             , source.ASSOC_PROV_ADR_LN1_TXT
             , source.ASSOC_PROV_ADR_LN2_TXT
             , source.ASSOC_PROV_ADR_CTY_NM
             , source.ASSOC_PROV_ADR_ST_CD
             , source.ASSOC_PROV_ADR_ZIP_FULL_CD
             , source.ASSOC_PROV_ASGN_RNDR_IND
             , source.ASSOC_PROV_GRP_TYP_CD
             , source.ASSOC_PROV_GRP_ID
             , source.ASSOC_PROV_GRP_NM
             , source.ASSOC_HLTH_SYS_ID
             , source.ASSOC_HLTH_SYS_NM
             , source.ROW_INSRT_DT
             , source.LST_HICN_BFR_MBI
             , source.SegmentID
             , source.MSR_RSLT_86
             , source.PARTD_ALRT_LVL_86
             , source.MSR_RSLT_CY_86
             , source.Load_Date_Py
             , source.CountOfFiles
             , source.FileName
             , GETDATE()
             , 'Active'
             , 'New'
            )
WHEN MATCHED
 AND (    source.MBR_VDS_ID                  <> target.MBR_VDS_ID
       OR source.MBR_INDV_ID                 <> target.MBR_INDV_ID
       OR source.MBR_CRD_ID                  <> target.MBR_CRD_ID
       OR source.MBR_CURR_CMS_CONTR_NUM      <> target.MBR_CURR_CMS_CONTR_NUM
       OR source.MBR_CURR_CMS_PBP_CD         <> target.MBR_CURR_CMS_PBP_CD
       OR source.MBR_LST_NM                  <> target.MBR_LST_NM
       OR source.MBR_FST_NM                  <> target.MBR_FST_NM
       OR source.MBR_MIDL_INIT               <> target.MBR_MIDL_INIT
       OR source.MBR_DOB                     <> target.MBR_DOB
       OR source.MBR_GDR_CD                  <> target.MBR_GDR_CD
       OR source.MBR_ADR_LN1_TXT             <> target.MBR_ADR_LN1_TXT
       OR source.MBR_ADR_LN2_TXT             <> target.MBR_ADR_LN2_TXT
       OR source.MBR_ADR_CTY_NM              <> target.MBR_ADR_CTY_NM
       OR source.MBR_ADR_ST_CD               <> target.MBR_ADR_ST_CD
       OR source.MBR_ADR_ZIP_FULL_CD         <> target.MBR_ADR_ZIP_FULL_CD
       OR source.MBR_DAY_PH_NUM              <> target.MBR_DAY_PH_NUM
       OR source.MBR_ANNL_CARE_VST_FLG       <> target.MBR_ANNL_CARE_VST_FLG
       OR source.MBR_ANNL_CARE_VST_DT        <> target.MBR_ANNL_CARE_VST_DT
       OR source.MBR_ANNL_CARE_VST_DT_HC     <> target.MBR_ANNL_CARE_VST_DT_HC
       OR source.MBR_DIAB_IND                <> target.MBR_DIAB_IND
       OR source.MBR_INCNT_PGM_IND           <> target.MBR_INCNT_PGM_IND
       OR source.MBR_TYP_CD                  <> target.MBR_TYP_CD
       OR source.SRC_SYS                     <> target.SRC_SYS
       OR source.ASGN_PROV_VDS_ID            <> target.ASGN_PROV_VDS_ID
       OR source.ASGN_PROV_MPIN_NUM          <> target.ASGN_PROV_MPIN_NUM
       OR source.ASGN_PROV_NPI_NUM           <> target.ASGN_PROV_NPI_NUM
       OR source.ASGN_PROV_TIN_NUM           <> target.ASGN_PROV_TIN_NUM
       OR source.ASGN_PROV_LST_NM            <> target.ASGN_PROV_LST_NM
       OR source.ASGN_PROV_FST_NM            <> target.ASGN_PROV_FST_NM
       OR source.ASGN_PROV_ADR_LN1_TXT       <> target.ASGN_PROV_ADR_LN1_TXT
       OR source.ASGN_PROV_ADR_LN2_TXT       <> target.ASGN_PROV_ADR_LN2_TXT
       OR source.ASGN_PROV_ADR_CTY_NM        <> target.ASGN_PROV_ADR_CTY_NM
       OR source.ASGN_PROV_ADR_ST_CD         <> target.ASGN_PROV_ADR_ST_CD
       OR source.ASGN_PROV_ADR_ZIP_FULL_CD   <> target.ASGN_PROV_ADR_ZIP_FULL_CD
       OR source.MSR_1_BCS_RSLT              <> target.MSR_1_BCS_RSLT
       OR source.MSR_2_COL_RSLT              <> target.MSR_2_COL_RSLT
       OR source.MSR_3_CMCSCR_RSLT           <> target.MSR_3_CMCSCR_RSLT
       OR source.MSR_4_CDCLPP_RSLT           <> target.MSR_4_CDCLPP_RSLT
       OR source.MSR_5_GSO_RSLT              <> target.MSR_5_GSO_RSLT
       OR source.MSR_12_ABA_RSLT             <> target.MSR_12_ABA_RSLT
       OR source.MSR_13_COAMR_RSLT           <> target.MSR_13_COAMR_RSLT
       OR source.MSR_14_COAFSA_RSLT          <> target.MSR_14_COAFSA_RSLT
       OR source.MSR_15_COAPS_RSLT           <> target.MSR_15_COAPS_RSLT
       OR source.MSR_16_OMW_RSLT             <> target.MSR_16_OMW_RSLT
       OR source.MSR_16_OMW_DT               <> target.MSR_16_OMW_DT
       OR source.MSR_91_OMWX_RSLT            <> target.MSR_91_OMWX_RSLT
       OR source.MSR_91_OMWX_DT              <> target.MSR_91_OMWX_DT
       OR source.MSR_17_CDCEYE_RSLT          <> target.MSR_17_CDCEYE_RSLT
       OR source.MSR_18_CDCNEP_RSLT          <> target.MSR_18_CDCNEP_RSLT
       OR source.MSR_19_CDCA1C9_RSLT         <> target.MSR_19_CDCA1C9_RSLT
       OR source.MSR_20_CDC100_RSLT          <> target.MSR_20_CDC100_RSLT
       OR source.MSR_21_CBP_RSLT             <> target.MSR_21_CBP_RSLT
       OR source.MSR_22_ART_RSLT             <> target.MSR_22_ART_RSLT
       OR source.MSR_49_HRM_PYR_RSLT         <> target.MSR_49_HRM_PYR_RSLT
       OR source.MSR_49_HRM_CYR_STS          <> target.MSR_49_HRM_CYR_STS
       OR source.MSR_49_HRM_CYR_RSLT         <> target.MSR_49_HRM_CYR_RSLT
       OR source.MSR_51_MAD_PYR_RSLT         <> target.MSR_51_MAD_PYR_RSLT
       OR source.MSR_51_MAD_CYR_STS          <> target.MSR_51_MAD_CYR_STS
       OR source.MSR_51_MAD_CYR_RSLT         <> target.MSR_51_MAD_CYR_RSLT
       OR source.MSR_51_MAD_CURR_PDC         <> target.MSR_51_MAD_CURR_PDC
       OR source.MSR_51_MAD_FA_CYR_RSLT      <> target.MSR_51_MAD_FA_CYR_RSLT
       OR source.MSR_51_MAD_AD               <> target.MSR_51_MAD_AD
       OR source.MSR_51_MAD_DM45             <> target.MSR_51_MAD_DM45
       OR source.MSR_51_MAD_EOY_PDC_PRED     <> target.MSR_51_MAD_EOY_PDC_PRED
       OR source.MSR_52_MAH_PYR_RSLT         <> target.MSR_52_MAH_PYR_RSLT
       OR source.MSR_52_MAH_CYR_STS          <> target.MSR_52_MAH_CYR_STS
       OR source.MSR_52_MAH_CYR_RSLT         <> target.MSR_52_MAH_CYR_RSLT
       OR source.MSR_52_MAH_CURR_PDC         <> target.MSR_52_MAH_CURR_PDC
       OR source.MSR_52_MAH_FA_CYR_RSLT      <> target.MSR_52_MAH_FA_CYR_RSLT
       OR source.MSR_52_MAH_AD               <> target.MSR_52_MAH_AD
       OR source.MSR_52_MAH_DM45             <> target.MSR_52_MAH_DM45
       OR source.MSR_52_MAH_EOY_PDC_PRED     <> target.MSR_52_MAH_EOY_PDC_PRED
       OR source.MSR_53_MAC_PYR_RSLT         <> target.MSR_53_MAC_PYR_RSLT
       OR source.MSR_53_MAC_CYR_STS          <> target.MSR_53_MAC_CYR_STS
       OR source.MSR_53_MAC_CYR_RSLT         <> target.MSR_53_MAC_CYR_RSLT
       OR source.MSR_53_MAC_CURR_PDC         <> target.MSR_53_MAC_CURR_PDC
       OR source.MSR_53_MAC_FA_CYR_RSLT      <> target.MSR_53_MAC_FA_CYR_RSLT
       OR source.MSR_53_MAC_AD               <> target.MSR_53_MAC_AD
       OR source.MSR_53_MAC_DM45             <> target.MSR_53_MAC_DM45
       OR source.MSR_53_MAC_EOY_PDC_PRED     <> target.MSR_53_MAC_EOY_PDC_PRED
       OR source.MSR_100_SUPD_PYR_RSLT       <> target.MSR_100_SUPD_PYR_RSLT
       OR source.MSR_100_SUPD_CYR_STS        <> target.MSR_100_SUPD_CYR_STS
       OR source.MSR_100_SUPD_CYR_RSLT       <> target.MSR_100_SUPD_CYR_RSLT
       OR source.MSR_101_SPC_RSLT            <> target.MSR_101_SPC_RSLT
       OR source.MSR_58_FMI_RSLT             <> target.MSR_58_FMI_RSLT
       OR source.MSR_60_AMM_RSLT             <> target.MSR_60_AMM_RSLT
       OR source.MSR_61_BBT_RSLT             <> target.MSR_61_BBT_RSLT
       OR source.MSR_62_MPLM_RSLT            <> target.MSR_62_MPLM_RSLT
       OR source.MSR_64_COPD_RSLT            <> target.MSR_64_COPD_RSLT
       OR source.MSR_71_PCE_SC_RSLT          <> target.MSR_71_PCE_SC_RSLT
       OR source.MSR_72_PCEBRON_RSLT         <> target.MSR_72_PCEBRON_RSLT
       OR source.MSR_73_AODRINITOT_RSLT      <> target.MSR_73_AODRINITOT_RSLT
       OR source.MSR_74_EADT_RSLT            <> target.MSR_74_EADT_RSLT
       OR source.ASSOC_PROV_VDS_ID           <> target.ASSOC_PROV_VDS_ID
       OR source.ASSOC_PROV_MPIN_NUM         <> target.ASSOC_PROV_MPIN_NUM
       OR source.ASSOC_PROV_NPI_NUM          <> target.ASSOC_PROV_NPI_NUM
       OR source.ASSOC_PROV_TIN              <> target.ASSOC_PROV_TIN
       OR source.ASSOC_PROV_LST_NM           <> target.ASSOC_PROV_LST_NM
       OR source.ASSOC_PROV_FST_NM           <> target.ASSOC_PROV_FST_NM
       OR source.ASSOC_PROV_ADR_LN1_TXT      <> target.ASSOC_PROV_ADR_LN1_TXT
       OR source.ASSOC_PROV_ADR_LN2_TXT      <> target.ASSOC_PROV_ADR_LN2_TXT
       OR source.ASSOC_PROV_ADR_CTY_NM       <> target.ASSOC_PROV_ADR_CTY_NM
       OR source.ASSOC_PROV_ADR_ST_CD        <> target.ASSOC_PROV_ADR_ST_CD
       OR source.ASSOC_PROV_ADR_ZIP_FULL_CD  <> target.ASSOC_PROV_ADR_ZIP_FULL_CD
       OR source.ASSOC_PROV_ASGN_RNDR_IND    <> target.ASSOC_PROV_ASGN_RNDR_IND
       OR source.ASSOC_PROV_GRP_TYP_CD       <> target.ASSOC_PROV_GRP_TYP_CD
       OR source.ASSOC_PROV_GRP_ID           <> target.ASSOC_PROV_GRP_ID
       OR source.ASSOC_PROV_GRP_NM           <> target.ASSOC_PROV_GRP_NM
       OR source.ASSOC_HLTH_SYS_ID           <> target.ASSOC_HLTH_SYS_ID
       OR source.ASSOC_HLTH_SYS_NM           <> target.ASSOC_HLTH_SYS_NM
       OR source.ROW_INSRT_DT                <> target.ROW_INSRT_DT
       OR source.LST_HICN_BFR_MBI            <> target.LST_HICN_BFR_MBI
       OR source.SegmentID                   <> target.SegmentID
       OR source.MSR_RSLT_86                 <> target.MSR_RSLT_86
       OR source.PARTD_ALRT_LVL_86           <> target.PARTD_ALRT_LVL_86
       OR source.MSR_RSLT_CY_86              <> target.MSR_RSLT_CY_86
       OR source.FileName                    <> target.FileName
     )
THEN UPDATE 
        SET target.MBR_VDS_ID                  = source.MBR_VDS_ID
          , target.MBR_INDV_ID                 = source.MBR_INDV_ID
          , target.MBR_INDV_ID_STR             = source.MBR_INDV_ID_STR
          , target.MBR_CRD_ID                  = source.MBR_CRD_ID
          , target.MBR_CURR_CMS_CONTR_NUM      = source.MBR_CURR_CMS_CONTR_NUM
          , target.MBR_CURR_CMS_PBP_CD         = source.MBR_CURR_CMS_PBP_CD
          , target.MBR_LST_NM                  = source.MBR_LST_NM
          , target.MBR_FST_NM                  = source.MBR_FST_NM
          , target.MBR_MIDL_INIT               = source.MBR_MIDL_INIT
          , target.MBR_DOB                     = source.MBR_DOB
          , target.MBR_GDR_CD                  = source.MBR_GDR_CD
          , target.MBR_ADR_LN1_TXT             = source.MBR_ADR_LN1_TXT
          , target.MBR_ADR_LN2_TXT             = source.MBR_ADR_LN2_TXT
          , target.MBR_ADR_CTY_NM              = source.MBR_ADR_CTY_NM
          , target.MBR_ADR_ST_CD               = source.MBR_ADR_ST_CD
          , target.MBR_ADR_ZIP_FULL_CD         = source.MBR_ADR_ZIP_FULL_CD
          , target.MBR_DAY_PH_NUM              = source.MBR_DAY_PH_NUM
          , target.MBR_ANNL_CARE_VST_FLG       = source.MBR_ANNL_CARE_VST_FLG
          , target.MBR_ANNL_CARE_VST_DT        = source.MBR_ANNL_CARE_VST_DT
          , target.MBR_ANNL_CARE_VST_DT_HC     = source.MBR_ANNL_CARE_VST_DT_HC
          , target.MBR_DIAB_IND                = source.MBR_DIAB_IND
          , target.MBR_INCNT_PGM_IND           = source.MBR_INCNT_PGM_IND
          , target.MBR_TYP_CD                  = source.MBR_TYP_CD
          , target.SRC_SYS                     = source.SRC_SYS
          , target.ASGN_PROV_VDS_ID            = source.ASGN_PROV_VDS_ID
          , target.ASGN_PROV_MPIN_NUM          = source.ASGN_PROV_MPIN_NUM
          , target.ASGN_PROV_NPI_NUM           = source.ASGN_PROV_NPI_NUM
          , target.ASGN_PROV_TIN_NUM           = source.ASGN_PROV_TIN_NUM
          , target.ASGN_PROV_LST_NM            = source.ASGN_PROV_LST_NM
          , target.ASGN_PROV_FST_NM            = source.ASGN_PROV_FST_NM
          , target.ASGN_PROV_ADR_LN1_TXT       = source.ASGN_PROV_ADR_LN1_TXT
          , target.ASGN_PROV_ADR_LN2_TXT       = source.ASGN_PROV_ADR_LN2_TXT
          , target.ASGN_PROV_ADR_CTY_NM        = source.ASGN_PROV_ADR_CTY_NM
          , target.ASGN_PROV_ADR_ST_CD         = source.ASGN_PROV_ADR_ST_CD
          , target.ASGN_PROV_ADR_ZIP_FULL_CD   = source.ASGN_PROV_ADR_ZIP_FULL_CD
          , target.MSR_1_BCS_RSLT              = source.MSR_1_BCS_RSLT
          , target.MSR_2_COL_RSLT              = source.MSR_2_COL_RSLT
          , target.MSR_3_CMCSCR_RSLT           = source.MSR_3_CMCSCR_RSLT
          , target.MSR_4_CDCLPP_RSLT           = source.MSR_4_CDCLPP_RSLT
          , target.MSR_5_GSO_RSLT              = source.MSR_5_GSO_RSLT
          , target.MSR_12_ABA_RSLT             = source.MSR_12_ABA_RSLT
          , target.MSR_13_COAMR_RSLT           = source.MSR_13_COAMR_RSLT
          , target.MSR_14_COAFSA_RSLT          = source.MSR_14_COAFSA_RSLT
          , target.MSR_15_COAPS_RSLT           = source.MSR_15_COAPS_RSLT
          , target.MSR_16_OMW_RSLT             = source.MSR_16_OMW_RSLT
          , target.MSR_16_OMW_DT               = source.MSR_16_OMW_DT
          , target.MSR_91_OMWX_RSLT            = source.MSR_91_OMWX_RSLT
          , target.MSR_91_OMWX_DT              = source.MSR_91_OMWX_DT
          , target.MSR_17_CDCEYE_RSLT          = source.MSR_17_CDCEYE_RSLT
          , target.MSR_18_CDCNEP_RSLT          = source.MSR_18_CDCNEP_RSLT
          , target.MSR_19_CDCA1C9_RSLT         = source.MSR_19_CDCA1C9_RSLT
          , target.MSR_20_CDC100_RSLT          = source.MSR_20_CDC100_RSLT
          , target.MSR_21_CBP_RSLT             = source.MSR_21_CBP_RSLT
          , target.MSR_22_ART_RSLT             = source.MSR_22_ART_RSLT
          , target.MSR_49_HRM_PYR_RSLT         = source.MSR_49_HRM_PYR_RSLT
          , target.MSR_49_HRM_CYR_STS          = source.MSR_49_HRM_CYR_STS
          , target.MSR_49_HRM_CYR_RSLT         = source.MSR_49_HRM_CYR_RSLT
          , target.MSR_51_MAD_PYR_RSLT         = source.MSR_51_MAD_PYR_RSLT
          , target.MSR_51_MAD_CYR_STS          = source.MSR_51_MAD_CYR_STS
          , target.MSR_51_MAD_CYR_RSLT         = source.MSR_51_MAD_CYR_RSLT
          , target.MSR_51_MAD_CURR_PDC         = source.MSR_51_MAD_CURR_PDC
          , target.MSR_51_MAD_FA_CYR_RSLT      = source.MSR_51_MAD_FA_CYR_RSLT
          , target.MSR_51_MAD_AD               = source.MSR_51_MAD_AD
          , target.MSR_51_MAD_DM45             = source.MSR_51_MAD_DM45
          , target.MSR_51_MAD_EOY_PDC_PRED     = source.MSR_51_MAD_EOY_PDC_PRED
          , target.MSR_52_MAH_PYR_RSLT         = source.MSR_52_MAH_PYR_RSLT
          , target.MSR_52_MAH_CYR_STS          = source.MSR_52_MAH_CYR_STS
          , target.MSR_52_MAH_CYR_RSLT         = source.MSR_52_MAH_CYR_RSLT
          , target.MSR_52_MAH_CURR_PDC         = source.MSR_52_MAH_CURR_PDC
          , target.MSR_52_MAH_FA_CYR_RSLT      = source.MSR_52_MAH_FA_CYR_RSLT
          , target.MSR_52_MAH_AD               = source.MSR_52_MAH_AD
          , target.MSR_52_MAH_DM45             = source.MSR_52_MAH_DM45
          , target.MSR_52_MAH_EOY_PDC_PRED     = source.MSR_52_MAH_EOY_PDC_PRED
          , target.MSR_53_MAC_PYR_RSLT         = source.MSR_53_MAC_PYR_RSLT
          , target.MSR_53_MAC_CYR_STS          = source.MSR_53_MAC_CYR_STS
          , target.MSR_53_MAC_CYR_RSLT         = source.MSR_53_MAC_CYR_RSLT
          , target.MSR_53_MAC_CURR_PDC         = source.MSR_53_MAC_CURR_PDC
          , target.MSR_53_MAC_FA_CYR_RSLT      = source.MSR_53_MAC_FA_CYR_RSLT
          , target.MSR_53_MAC_AD               = source.MSR_53_MAC_AD
          , target.MSR_53_MAC_DM45             = source.MSR_53_MAC_DM45
          , target.MSR_53_MAC_EOY_PDC_PRED     = source.MSR_53_MAC_EOY_PDC_PRED
          , target.MSR_100_SUPD_PYR_RSLT       = source.MSR_100_SUPD_PYR_RSLT
          , target.MSR_100_SUPD_CYR_STS        = source.MSR_100_SUPD_CYR_STS
          , target.MSR_100_SUPD_CYR_RSLT       = source.MSR_100_SUPD_CYR_RSLT
          , target.MSR_101_SPC_RSLT            = source.MSR_101_SPC_RSLT
          , target.MSR_58_FMI_RSLT             = source.MSR_58_FMI_RSLT
          , target.MSR_60_AMM_RSLT             = source.MSR_60_AMM_RSLT
          , target.MSR_61_BBT_RSLT             = source.MSR_61_BBT_RSLT
          , target.MSR_62_MPLM_RSLT            = source.MSR_62_MPLM_RSLT
          , target.MSR_64_COPD_RSLT            = source.MSR_64_COPD_RSLT
          , target.MSR_71_PCE_SC_RSLT          = source.MSR_71_PCE_SC_RSLT
          , target.MSR_72_PCEBRON_RSLT         = source.MSR_72_PCEBRON_RSLT
          , target.MSR_73_AODRINITOT_RSLT      = source.MSR_73_AODRINITOT_RSLT
          , target.MSR_74_EADT_RSLT            = source.MSR_74_EADT_RSLT
          , target.ASSOC_PROV_VDS_ID           = source.ASSOC_PROV_VDS_ID
          , target.ASSOC_PROV_MPIN_NUM         = source.ASSOC_PROV_MPIN_NUM
          , target.ASSOC_PROV_NPI_NUM          = source.ASSOC_PROV_NPI_NUM
          , target.ASSOC_PROV_TIN              = source.ASSOC_PROV_TIN
          , target.ASSOC_PROV_LST_NM           = source.ASSOC_PROV_LST_NM
          , target.ASSOC_PROV_FST_NM           = source.ASSOC_PROV_FST_NM
          , target.ASSOC_PROV_ADR_LN1_TXT      = source.ASSOC_PROV_ADR_LN1_TXT
          , target.ASSOC_PROV_ADR_LN2_TXT      = source.ASSOC_PROV_ADR_LN2_TXT
          , target.ASSOC_PROV_ADR_CTY_NM       = source.ASSOC_PROV_ADR_CTY_NM
          , target.ASSOC_PROV_ADR_ST_CD        = source.ASSOC_PROV_ADR_ST_CD
          , target.ASSOC_PROV_ADR_ZIP_FULL_CD  = source.ASSOC_PROV_ADR_ZIP_FULL_CD
          , target.ASSOC_PROV_ASGN_RNDR_IND    = source.ASSOC_PROV_ASGN_RNDR_IND
          , target.ASSOC_PROV_GRP_TYP_CD       = source.ASSOC_PROV_GRP_TYP_CD
          , target.ASSOC_PROV_GRP_ID           = source.ASSOC_PROV_GRP_ID
          , target.ASSOC_PROV_GRP_NM           = source.ASSOC_PROV_GRP_NM
          , target.ASSOC_HLTH_SYS_ID           = source.ASSOC_HLTH_SYS_ID
          , target.ASSOC_HLTH_SYS_NM           = source.ASSOC_HLTH_SYS_NM
          , target.ROW_INSRT_DT                = source.ROW_INSRT_DT
          , target.LST_HICN_BFR_MBI            = source.LST_HICN_BFR_MBI
          , target.SegmentID                   = source.SegmentID
          , target.MSR_RSLT_86                 = source.MSR_RSLT_86
          , target.PARTD_ALRT_LVL_86           = source.PARTD_ALRT_LVL_86
          , target.MSR_RSLT_CY_86              = source.MSR_RSLT_CY_86
          , target.Load_Date_Py                = source.Load_Date_Py
          , target.CountOfFiles                = source.CountOfFiles + 1
          , target.FileName                    = source.FileName
          , target.LastModifiedDate            = GETDATE()
          , target.MnR_Status                  = 'Active'
          , target.MnR_SubStatus               = 'Updated'
WHEN NOT MATCHED BY source
THEN UPDATE
        SET target.DropDate      = GETDATE()
          , target.MnR_Status    = 'Inactive'
          , target.MnR_SubStatus = 'Dropped'
;
