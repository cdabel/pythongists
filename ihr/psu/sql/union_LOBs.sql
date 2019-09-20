WITH
cte_source AS 
(
     WITH
       cte_ei_aco AS
     (
     SELECT DISTINCT
            MBR_ID
          , pred
          , pred_flag
          , aco_flag
          , ACO
          , group_nm
          , referral
          , PRSPCTV_RISK
          , condition_count
     FROM [IHR_RAP].[stage].[PSU_EI_ACO_Latest]
     )
     , cte_ei_rank_non AS 
     (
     SELECT *
          , ROW_NUMBER() OVER (PARTITION BY indv_id ORDER BY pred_flag DESC) AS rank_indv_id
     FROM [IHR_RAP].[stage].[PSU_EI_Latest] 
     )
     , cte_ei_dedupe_non AS 
     (
     SELECT *
     FROM cte_ei_rank_non
     WHERE 1=1
       AND rank_indv_id = 1 
     )
     , cte_ei AS
     (
     SELECT 'E&I'                                               AS LineOfBusiness
          -- Get first day of month of date ingested:
          --, CONVERT( date, DATEADD(MONTH, DATEDIFF(MONTH, 0, CONVERT(date, non.date_ingested)), 0))  
          , FORMAT(CONVERT(date, non.date_ingested), 'yyyyMM')  AS YYYYMM
          , non.MBR_ID                                          AS Member_ID  -- TODO: Make this column an index column (on create) 
          , non.MBR_FST_NM                                      AS MemberFirstName
          , non.MBR_LST_NM                                      AS MemberLastName
          , CONVERT(date, non.dob)                              AS Member_DOB
          , NULL                                                AS Subscriber_ID
          , non.indv_id                                         AS Indv_ID
          , non.MBR_GDR_CD                                      AS MemberGender
          , non.pred                                            AS HCE_PredictiveScore
          , non.pred_flag                                       AS PredictiveFlag
          , non.pred_cutoff                                     AS PredictiveCutoff
          , aco.aco_flag                                        AS ACO_Flag
          , aco.group_nm                                        AS ACO_Name -- review
          , non.Exchange_Ind                                    AS ExchangeInd
          , non.CUST_SEG_NBR                                    AS CustomerSegmentNumber
          , aco.group_nm                                        AS GroupName -- review
          , aco.referral                                        AS EI_Referral
          , non.MKT_RLLP_NM                                     AS MarketRollup
          , non.MKT_SEG_CD                                      AS MarketSegment
          , non.MBR_ZIP_CD                                      AS MemberZipCd
          , NULL                                                AS MemberZipPlus4Cd
          , non.MBR_CTY_NM                                      AS MemberCityName
          , non.MBR_HCFA_CNTY_NM                                AS MemberCounty
          , non.MBR_ST_ABBR_CD                                  AS MemberState
          , non.RCT                                             AS RCT
          -- MR Only:
          , NULL                                                AS MR_ContractNumber
          , NULL                                                AS MR_PBP
          , NULL                                                AS MR_Product
          , NULL                                                AS MR_PMG_Name
          , NULL                                                AS GI
          , NULL                                                AS CongestiveHeartFailure
          , NULL                                                AS Diabetes
          , NULL                                                AS EndStageRenal
          , NULL                                                AS TCM_eng
          , NULL                                                AS HRCM_eng
          , NULL                                                AS AI_eng
          , NULL                                                AS Any_Optum_Program
          -- CS Only:
          , NULL                                                AS CS_MemberKey
          , NULL                                                AS CS_CompanyState
          , NULL                                                AS CS_file_origin
          , CONVERT(date, non.date_ingested)                    AS load_date_py
          -- TODO: Uncomment below once brought into stage tables
          , non.Filename                                        AS FileName
     --SELECT count(*)
     FROM cte_ei_dedupe_non non
     LEFT JOIN cte_ei_aco aco
            ON non.MBR_ID = aco.MBR_ID
     )
     , cte_mr AS
     (
     SELECT DISTINCT
            'M&R'                                               AS LineOfBusiness
          , FORMAT(CONVERT(date, date_ingested), 'yyyyMM')      AS YYYYMM
          , hicn                                                AS Member_ID
          , GPS_FIRST_NAME                                      AS MemberFirstName
          , GPS_LAST_NAME                                       AS MemberLastName
          , CONVERT(date, bth_dt)                               AS Member_DOB
          , NULL                                                AS Subscriber_ID
          , NULL                                                AS Indv_ID
          , FIN_GENDER                                          AS MemberGender
          , pred                                                AS HCE_PredictiveScore
          , pred_flag                                           AS PredictiveFlag
          , pred_cutoff                                         AS PredictiveCutoff
          , aco_flag                                            AS ACO_Flag
          , NULL                                                AS ACO_Name -- review
          , NULL                                                AS ExchangeInd
          , NULL                                                AS CustomerSegmentNumber
          , NULL                                                AS GroupName
          , NULL                                                AS EI_Referral
          , NULL                                                AS MarketRollup
          , NULL                                                AS MarketSegment
          , SUBSTRING(gps_zip_cd, 1, 5)                         AS MemberZipCd
          , CASE WHEN LEN(gps_zip_cd) > 5
                      THEN SUBSTRING(gps_zip_cd, 6, 9)
                      ELSE NULL 
            END                                                 AS MemberZipPlus4Cd
          , GPS_CITY                                            AS MemberCityName
          , fin_county_name                                     AS MemberCounty
          , FIN_STATE                                           AS MemberState
          -- EI Only:
          , NULL                                                AS RCT
          -- MR Only:
          , FIN_CONTRACT_NBR                                    AS MR_ContractNumber
          , FIN_PBP                                             AS MR_PBP
          , product                                             AS MR_Product
          , PMG_NAME                                            AS MR_PMG_Name
          , FIN_G_I                                             AS GI
          , CHF_eng                                             AS CongestiveHeartFailure
          , DIAB_eng                                            AS Diabetes
          , ESRD_eng                                            AS EndStageRenal
          , TCM_eng                                             AS TCM_eng
          , HRCM_eng                                            AS HRCM_eng
          , AI_eng                                              AS AI_eng
          , ANY_OPTUM_PGM                                       AS Any_Optum_Program
          -- CS Only:
          , NULL                                                AS CS_MemberKey
          , NULL                                                AS CS_CompanyState
          , NULL                                                AS CS_file_origin
          , CONVERT(date, date_ingested)                        AS load_date_py
          -- TODO: Uncomment below once brought into stage tables
          , Filename                                            AS FileName
     FROM [IHR_RAP].[stage].[PSU_MR_Latest]
     )
     , cte_cs AS
     (
     SELECT 'C&S'                                               AS LineOfBusiness
          , FORMAT(CONVERT(date, date_ingested), 'yyyyMM')      AS YYYYMM
          , Subscriber_ID                                       AS Member_ID
          , Member_First_Name                                   AS MemberFirstName
          , Member_Last_Name                                    AS MemberLastName
          , CONVERT(date, Member_DOB)                           AS Member_DOB
          , Subscriber_ID                                       AS Subscriber_ID
          , NULL                                                AS Indv_ID
          , NULL                                                AS MemberGender
          , pred_model                                          AS HCE_PredictiveScore
          , NULL                                                AS PredictiveFlag
          , NULL                                                AS PredictiveCutoff
          , NULL                                                AS ACO_Flag
          , NULL                                                AS ACO_Name -- review
          , NULL                                                AS ExchangeInd
          , NULL                                                AS CustomerSegmentNumber
          , NULL                                                AS GroupName
          , NULL                                                AS EI_Referral
          , NULL                                                AS MarketRollup
          , NULL                                                AS MarketSegment
          , NULL                                                AS MemberZipCd
          , NULL                                                AS MemberZipPlus4Cd
          , NULL                                                AS MemberCityName
          , NULL                                                AS MemberCounty
          , NULL                                                AS MemberState
          , NULL                                                AS RCT
          , NULL                                                AS MR_ContractNumber
          , NULL                                                AS MR_PBP
          , NULL                                                AS MR_Product
          , NULL                                                AS MR_PMG_Name
          , NULL                                                AS GI
          , NULL                                                AS CongestiveHeartFailure
          , NULL                                                AS Diabetes
          , NULL                                                AS EndStageRenal
          , NULL                                                AS TCM_eng
          , NULL                                                AS HRCM_eng
          , NULL                                                AS AI_eng
          , NULL                                                AS Any_Optum_Program
          , Member_Key                                          AS CS_MemberKey
          , COMPANY_DESC                                        AS CS_CompanyState
          , file_origin                                         AS CS_file_origin
          , CONVERT(date, date_ingested)                        AS load_date_py
          -- TODO: Uncomment below once brought into stage tables
          , FileName                                            AS FileName
     FROM [IHR_RAP].[stage].[PSU_CS_Latest]
     )
     , cte_union AS
     (
      SELECT --TOP 20 
        * 
      FROM cte_ei
     UNION ALL
      SELECT --TOP 20 
        * 
      FROM cte_mr
     UNION ALL
      SELECT --TOP 20 
        * 
      FROM cte_cs
     )
     SELECT LineOfBusiness                                       AS LineOfBusiness
          , YYYYMM                                               AS YYYYMM
          , Member_ID                                            AS Member_ID
          , MemberFirstName                                      AS MemberFirstName
          , MemberLastName                                       AS MemberLastName
          , Member_DOB                                           AS Member_DOB
          , Subscriber_ID                                        AS Subscriber_ID
          , Indv_ID                                              AS Indv_ID
          , CS_MemberKey                                         AS CS_MemberKey
          , CS_CompanyState                                      AS CS_CompanyState
          , CS_file_origin                                       AS CS_file_origin
          , MemberGender                                         AS MemberGender
          , HCE_PredictiveScore                                  AS HCE_PredictiveScore
          , PredictiveFlag                                       AS Is_PSU
          , PredictiveCutoff                                     AS PSU_Score_Cutoff
          , ACO_Flag                                             AS ACO_Flag
          , ACO_Name                                             AS ACO_Name
          , ExchangeInd                                          AS ExchangeInd
          , CustomerSegmentNumber                                AS CustomerSegmentNumber
          , GroupName                                            AS GroupName
          , EI_Referral                                          AS EI_Referral
          , MarketRollup                                         AS MarketRollup
          , MarketSegment                                        AS MarketSegment
          , MemberZipCd                                          AS MemberZipCd
          , MemberZipPlus4Cd                                     AS MemberZipPlus4Cd
          , MemberCityName                                       AS MemberCityName
          , MemberCounty                                         AS MemberCounty
          , MemberState                                          AS MemberState
          , MR_ContractNumber                                    AS MR_ContractNumber
          , MR_PBP                                               AS MR_PBP
          , MR_Product                                           AS MR_Product
          , MR_PMG_Name                                          AS MR_PMG_Name
          , GI                                                   AS GI
          , CongestiveHeartFailure                               AS CongestiveHeartFailure
          , Diabetes                                             AS Diabetes
          , EndStageRenal                                        AS EndStageRenal
          , TCM_eng                                              AS TCM_eng
          , HRCM_eng                                             AS HRCM_eng
          , AI_eng                                               AS AI_eng
          , Any_Optum_Program                                    AS Any_Optum_Program
          , RCT                                                  AS RCT
          , load_date_py                                         AS load_date_py
          , COUNT(*) OVER ( source.MemberFirstName
                          , source.MemberLastName
                          , source.Member_DOB
                          -- , source.MemberZipCd 
                          )                                      AS CountOf_LOB
         -- TODO: Uncomment once brought into stage tables
          , FileName                                             AS FileName
          , DENSE_RANK() OVER ( ORDER BY MemberFirstName, MemberLastName, Member_DOB )  AS Member_Key
     FROM cte_union
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
MERGE [IHR_RAP].[stage].[PSU_Combined]  AS target
USING cte_source                        AS source
   ON ( source.Member_ID = target.Member_ID )
WHEN NOT MATCHED
THEN INSERT (  LineOfBusiness
             , YYYYMM
             , Member_ID
             , MemberFirstName
             , MemberLastName
             , Member_DOB
             , Subscriber_ID
             , Indv_ID
             , MemberGender
             , HCE_PredictiveScore
             , Is_PSU
             , PSU_Score_Cutoff
             , ACO_Flag
             , ACO_Name
             , ExchangeInd
             , CustomerSegmentNumber
             , GroupName
             , EI_Referral
             , MarketRollup
             , MarketSegment
             , MemberZipCd
             , MemberZipPlus4Cd
             , MemberCityName
             , MemberCounty
             , MemberState
             , RCT
             , MR_ContractNumber
             , MR_PBP
             , MR_Product
             , MR_PMG_Name
             , GI
             , CongestiveHeartFailure
             , Diabetes
             , EndStageRenal
             , TCM_eng
             , HRCM_eng
             , AI_eng
             , Any_Optum_Program
             , CS_MemberKey
             , CS_CompanyState
             , CS_file_origin
             , load_date_py
             , CountOf_LOB
             , CountOfFiles
             , FileName
             , InsertDate
             , UpdateDate
             , DropDate
             , SuperUser_Status
             , SuperUser_SubStatus
            )
     VALUES (  source.LineOfBusiness
             , source.YYYYMM
             , source.MemberFirstName
             , source.MemberLastName
             , source.Member_DOB
             , source.Subscriber_ID
             , source.Indv_ID
             , source.MemberGender
             , source.HCE_PredictiveScore
             , source.PredictiveFlag
             , source.PredictiveCutoff
             , source.ACO_Flag
             , source.ACO_Name
             , source.ExchangeInd
             , source.CustomerSegmentNumber
             , source.GroupName
             , source.EI_Referral
             , source.MarketRollup
             , source.MarketSegment
             , source.MemberZipCd
             , source.MemberZipPlus4Cd
             , source.MemberCityName
             , source.MemberCounty
             , source.MemberState
             , source.RCT
             , source.MR_ContractNumber
             , source.MR_PBP
             , source.MR_Product
             , source.MR_PMG_Name
             , source.GI
             , source.CongestiveHeartFailure
             , source.Diabetes
             , source.EndStageRenal
             , source.TCM_eng
             , source.HRCM_eng
             , source.AI_eng
             , source.Any_Optum_Program
             , source.CS_MemberKey
             , source.CS_CompanyState
             , source.CS_file_origin
             , source.load_date_py
             , source.CountOf_LOB
             , 1                                     AS CountOfFiles
             , source.FileName
             , CONVERT(date, GETDATE())              AS InsertDate
             , CONVERT(date, GETDATE())              AS UpdateDate
             , NULL                                  AS DropDate
             , 'Active'                              AS SuperUser_Status
             , 'New'                                 AS SuperUser_SubStatus
            )
WHEN MATCHED
 AND (    source.MemberFirstName         <> target.MemberFirstName
       OR source.MemberLastName          <> target.MemberLastName
       OR source.Member_DOB              <> target.Member_DOB
       OR source.Subscriber_ID           <> target.Subscriber_ID
       OR source.Indv_ID                 <> target.Indv_ID
       OR source.MemberGender            <> target.MemberGender
       OR source.HCE_PredictiveScore     <> target.HCE_PredictiveScore
       OR source.PredictiveFlag          <> target.PredictiveFlag
       OR source.PredictiveCutoff        <> target.PredictiveCutoff
       OR source.ACO_Flag                <> target.ACO_Flag
       OR source.ACO_Name                <> target.ACO_Name
       OR source.ExchangeInd             <> target.ExchangeInd
       OR source.CustomerSegmentNumber   <> target.CustomerSegmentNumber
       OR source.GroupName               <> target.GroupName
       OR source.EI_Referral             <> target.EI_Referral
       OR source.MarketRollup            <> target.MarketRollup
       OR source.MarketSegment           <> target.MarketSegment
       OR source.MemberZipCd             <> target.MemberZipCd
       OR source.MemberZipPlus4Cd        <> target.MemberZipPlus4Cd
       OR source.MemberCityName          <> target.MemberCityName
       OR source.MemberCounty            <> target.MemberCounty
       OR source.MemberState             <> target.MemberState
       OR source.RCT                     <> target.RCT
       OR source.MR_ContractNumber       <> target.MR_ContractNumber
       OR source.MR_PBP                  <> target.MR_PBP
       OR source.MR_Product              <> target.MR_Product
       OR source.MR_PMG_Name             <> target.MR_PMG_Name
       OR source.GI                      <> target.GI
       OR source.CongestiveHeartFailure  <> target.CongestiveHeartFailure
       OR source.Diabetes                <> target.Diabetes
       OR source.EndStageRenal           <> target.EndStageRenal
       OR source.TCM_eng                 <> target.TCM_eng
       OR source.HRCM_eng                <> target.HRCM_eng
       OR source.AI_eng                  <> target.AI_eng
       OR source.Any_Optum_Program       <> target.Any_Optum_Program
       OR source.CS_MemberKey            <> target.CS_MemberKey
       OR source.CS_CompanyState         <> target.CS_CompanyState
       OR source.CS_file_origin          <> target.CS_file_origin
       OR source.FileName                <> target.FileName
     )
THEN UPDATE target 
        SET target.MemberFirstName         = source.MemberFirstName
          , target.MemberLastName          = source.MemberLastName
          , target.Member_DOB              = source.Member_DOB
          , target.Subscriber_ID           = source.Subscriber_ID
          , target.Indv_ID                 = source.Indv_ID
          , target.MemberGender            = source.MemberGender
          , target.HCE_PredictiveScore     = source.HCE_PredictiveScore
          , target.PredictiveFlag          = source.PredictiveFlag
          , target.PredictiveCutoff        = source.PredictiveCutoff
          , target.ACO_Flag                = source.ACO_Flag
          , target.ACO_Name                = source.ACO_Name
          , target.ExchangeInd             = source.ExchangeInd
          , target.CustomerSegmentNumber   = source.CustomerSegmentNumber
          , target.GroupName               = source.GroupName
          , target.EI_Referral             = source.EI_Referral
          , target.MarketRollup            = source.MarketRollup
          , target.MarketSegment           = source.MarketSegment
          , target.MemberZipCd             = source.MemberZipCd
          , target.MemberZipPlus4Cd        = source.MemberZipPlus4Cd
          , target.MemberCityName          = source.MemberCityName
          , target.MemberCounty            = source.MemberCounty
          , target.MemberState             = source.MemberState
          , target.RCT                     = source.RCT
          , target.MR_ContractNumber       = source.MR_ContractNumber
          , target.MR_PBP                  = source.MR_PBP
          , target.MR_Product              = source.MR_Product
          , target.MR_PMG_Name             = source.MR_PMG_Name
          , target.GI                      = source.GI
          , target.CongestiveHeartFailure  = source.CongestiveHeartFailure
          , target.Diabetes                = source.Diabetes
          , target.EndStageRenal           = source.EndStageRenal
          , target.TCM_eng                 = source.TCM_eng
          , target.HRCM_eng                = source.HRCM_eng
          , target.AI_eng                  = source.AI_eng
          , target.Any_Optum_Program       = source.Any_Optum_Program
          , target.CS_MemberKey            = source.CS_MemberKey
          , target.CS_CompanyState         = source.CS_CompanyState
          , target.file_origin             = source.CS_file_origin
          , target.CountOf_LOB             = source.CountOf_LOB
          , target.CountOfFiles            = target.CountOfFiles + 1
          , target.FileName                = source.FileName                    -- TODO: not yet brought in
          , target.UpdateDate              = CONVERT(date, GETDATE())
          , target.SuperUser_Status        = 'Active'
          , target.SuperUser_SubStatus     = 'Updated'
WHEN MATCHED
 AND target.Member_Key <> source.Member_Key
WHEN NOT MATCHED BY source
THEN UPDATE target
        SET target.DropDate = CONVERT(date, GETDATE())
          , target.SuperUser_Status        = 'Inactive'
          , target.SuperUser_SubStatus     = 'Dropped'


;