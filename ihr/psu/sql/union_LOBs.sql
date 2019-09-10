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
, cte_EI AS
(
SELECT CONVERT( VARCHAR(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, CONVERT(date, non.date_ingested)), 0), 120 )  
                                                         AS YYYYMM
     , non.MBR_ID                                        AS Member_ID  -- TODO: Make this column an index column (on create) 
     , non.MBR_FST_NM                                    AS MemberFirstName
     , non.MBR_LST_NM                                    AS MemberLastName
     , non.dob                                           AS Member_DOB
     , NULL                                              AS Subscriber_ID
     , non.indv_id                                       AS Indv_ID
     , non.MBR_GDR_CD                                    AS MemberGender
     , non.pred                                          AS HCE_PredictiveScore
     , non.pred_flag                                     AS PredictiveFlag
     , non.pred_cutoff                                   AS PredictiveCutoff
     , aco.aco_flag                                      AS ACO_Flag
     , aco.group_nm                                      AS ACO_Name -- review
     , non.Exchange_Ind                                  AS ExchangeInd
     , non.CUST_SEG_NBR                                  AS CustomerSegmentNumber
     , aco.group_nm                                      AS GroupName -- review
     , aco.referral                                      AS EI_Referral
     , non.MKT_RLLP_NM                                   AS MarketRollup
     , non.MKT_SEG_CD                                    AS MarketSegment
     , non.MBR_ZIP_CD                                    AS MemberZipCd
     , NULL                                              AS MemberZipPlus4Cd
     , non.MBR_CTY_NM                                    AS MemberCityName
     , non.MBR_HCFA_CNTY_NM                              AS MemberCounty
     , non.MBR_ST_ABBR_CD                                AS MemberState
     , non.RCT                                           AS RCT
     -- MR Only:
     , NULL                                              AS MR_ContractNumber
     , NULL                                              AS MR_PBP
     , NULL                                              AS MR_Product
     , NULL                                              AS MR_PMG_Name
     , NULL                                              AS GI
     , NULL                                              AS CongestiveHeartFailure
     , NULL                                              AS Diabetes
     , NULL                                              AS EndStageRenal
     , NULL                                              AS TCM_eng
     , NULL                                              AS HRCM_eng
     , NULL                                              AS AI_eng
     , NULL                                              AS Any_Optum_Program
     -- CS Only:
     , NULL                                              AS CS_MemberKey
     , NULL                                              AS CS_CompanyState
     , NULL                                              AS CS_file_origin
--SELECT count(*) 
FROM [IHR_RAP].[stage].[PSU_EI_Latest] non
LEFT JOIN cte_ei_aco aco
       ON non.MBR_ID = aco.MBR_ID
)
, cte_mr AS 
(
SELECT DISTINCT
       CONVERT(VARCHAR(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, CONVERT(date, date_ingested)), 0), 120)  
                                                         AS YYYYMM
     , hicn                                              AS Member_ID
     , GPS_FIRST_NAME                                    AS MemberFirstName
     , GPS_LAST_NAME                                     AS MemberLastName
     , CONVERT( VARCHAR(10), CONVERT(date, bth_dt), 23)  AS Member_DOB
     , NULL                                              AS Subscriber_ID
     , NULL                                              AS Indv_ID
     , FIN_GENDER                                        AS MemberGender
     , pred                                              AS HCE_PredictiveScore
     , pred_flag                                         AS PredictiveFlag
     , pred_cutoff                                       AS PredictiveCutoff
     , aco_flag                                          AS ACO_Flag
     , NULL                                              AS ACO_Name -- review
     , NULL                                              AS ExchangeInd
     , NULL                                              AS CustomerSegmentNumber
     , NULL                                              AS GroupName
     , NULL                                              AS EI_Referral
     , NULL                                              AS MarketRollup
     , NULL                                              AS MarketSegment
     , SUBSTRING(gps_zip_cd, 1, 5)                       AS MemberZipCd
     , CASE WHEN LEN(gps_zip_cd) > 5
                 THEN SUBSTRING(gps_zip_cd, 6, 9)
                 ELSE NULL 
       END                                               AS MemberZipPlus4Cd
     , GPS_CITY                                          AS MemberCityName
     , fin_county_name                                   AS MemberCounty
     , FIN_STATE                                         AS MemberState
     --EI Only:
     , NULL                                              AS RCT
     -- MR Only:
     , FIN_CONTRACT_NBR                                  AS MR_ContractNumber
     , FIN_PBP                                           AS MR_PBP
     , product                                           AS MR_Product
     , PMG_NAME                                          AS MR_PMG_Name
     , FIN_G_I                                           AS GI
     , CHF_eng                                           AS CongestiveHeartFailure
     , DIAB_eng                                          AS Diabetes
     , ESRD_eng                                          AS EndStageRenal
     , TCM_eng                                           AS TCM_eng
     , HRCM_eng                                          AS HRCM_eng
     , AI_eng                                            AS AI_eng
     , ANY_OPTUM_PGM                                     AS Any_Optum_Program
     -- CS Only:
     , NULL                                              AS CS_MemberKey
     , NULL                                              AS CS_CompanyState
     , NULL                                              AS CS_file_origin
FROM [IHR_RAP].[stage].[PSU_MR_Latest]
)
, cte_CS AS 
(
SELECT CONVERT(VARCHAR(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, CONVERT(date, date_ingested)), 0), 120)
                                                         AS YYYYMM
     , Subscriber_ID                                     AS Member_ID
     , Member_First_Name                                 AS MemberFirstName
     , Member_Last_Name                                  AS MemberLastName
     , Member_DOB                                        AS Member_DOB
     , Subscriber_ID                                     AS Subscriber_ID
     , NULL                                              AS Indv_ID
     , NULL                                              AS MemberGender
     , pred_model                                        AS HCE_PredictiveScore
     , NULL                                              AS PredictiveFlag
     , NULL                                              AS PredictiveCutoff
     , NULL                                              AS ACO_Flag
     , NULL                                              AS ACO_Name -- review
     , NULL                                              AS ExchangeInd
     , NULL                                              AS CustomerSegmentNumber
     , NULL                                              AS GroupName
     , NULL                                              AS EI_Referral
     , NULL                                              AS MarketRollup
     , NULL                                              AS MarketSegment
     , NULL                                              AS MemberZipCd
     , NULL                                              AS MemberZipPlus4Cd
     , NULL                                              AS MemberCityName
     , NULL                                              AS MemberCounty
     , NULL                                              AS MemberState
     , NULL                                              AS RCT
     , NULL                                              AS MR_ContractNumber
     , NULL                                              AS MR_PBP
     , NULL                                              AS MR_Product
     , NULL                                              AS MR_PMG_Name
     , NULL                                              AS GI
     , NULL                                              AS CongestiveHeartFailure
     , NULL                                              AS Diabetes
     , NULL                                              AS EndStageRenal
     , NULL                                              AS TCM_eng
     , NULL                                              AS HRCM_eng
     , NULL                                              AS AI_eng
     , NULL                                              AS Any_Optum_Program
     , Member_Key                                        AS CS_MemberKey
     , COMPANY_DESC                                      AS CS_CompanyState
     , file_origin                                       AS CS_file_origin
FROM [IHR_RAP].[stage].[PSU_CS_Latest]
)
