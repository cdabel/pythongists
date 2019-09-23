USE [IHR_RAP];
GO


DROP TABLE [IHR_RAP].[Member].[PSU_Combined]
;


CREATE TABLE [IHR_RAP].[Member].[PSU_Combined] 
(   Primary_Key             BIGINT IDENTITY(10000000000, 1)  NOT NULL  PRIMARY KEY
  , Member_Key              VARCHAR(32)                      NOT NULL
  , LineOfBusiness          VARCHAR(3)                       NOT NULL
  , YYYYMM                  VARCHAR(6)                           NULL
  , Member_ID               VARCHAR(50)                      NOT NULL
  , MemberFirstName         VARCHAR(255)                         NULL
  , MemberLastName          VARCHAR(255)                         NULL
  , Member_DOB              DATE                                 NULL
  , Subscriber_ID           VARCHAR(50)                          NULL
  , Indv_ID                 VARCHAR(50)                          NULL
  , CS_MemberKey            VARCHAR(50)                          NULL
  , CS_CompanyState         VARCHAR(50)                          NULL
  , CS_file_origin          VARCHAR(3)                           NULL
  , MemberGender            VARCHAR(3)                           NULL
  , HCE_PredictiveScore     DECIMAL(10,4)                        NULL
  , Is_PSU                  BIT                                  NULL
  , PSU_Score_Cutoff        DECIMAL(10,4)                        NULL
  , ACO_Flag                BIT                                  NULL
  , ACO_Name                VARCHAR(255)                         NULL
  , ExchangeInd             VARCHAR(1)                           NULL
  , CustomerSegmentNumber   VARCHAR(20)                          NULL
  , GroupName               VARCHAR(255)                         NULL
  , EI_Referral             VARCHAR(10)                          NULL
  , MarketRollup            VARCHAR(255)                         NULL
  , MarketSegment           VARCHAR(3)                           NULL
  , MemberZipCd             VARCHAR(10)                          NULL
  , MemberZipPlus4Cd        VARCHAR(10)                          NULL
  , MemberCityName          VARCHAR(255)                         NULL
  , MemberCounty            VARCHAR(255)                         NULL
  , MemberState             VARCHAR(2)                           NULL
  , MR_ContractNumber       VARCHAR(10)                          NULL
  , MR_PBP                  VARCHAR(10)                          NULL
  , MR_Product              VARCHAR(50)                          NULL
  , MR_PMG_Name             VARCHAR(50)                          NULL
  , GI                      VARCHAR(10)                          NULL
  , CongestiveHeartFailure  INT                                  NULL
  , Diabetes                INT                                  NULL
  , EndStageRenal           INT                                  NULL
  , TCM_eng                 INT                                  NULL
  , HRCM_eng                INT                                  NULL
  , AI_eng                  INT                                  NULL
  , Any_Optum_Program       INT                                  NULL
  , RCT                     INT                                  NULL
  , Load_Date_Py            DATE                                 NULL
  , CountOf_LOB             INT                                  NULL
  , CountOfFiles            INT                                  NULL
  , FileName                VARCHAR(255)                         NULL
  , InsertDate              DATE                                 NULL
  , LastModifiedDate        DATE                                 NULL
  , DropDate                DATE                                 NULL
  , SuperUser_Status        VARCHAR(40)                          NULL
  , SuperUser_SubStatus     VARCHAR(40)                          NULL

  -- This creates a non-clustered index on (Member_ID)
  , INDEX IX_PSU_Combined_Member_ID NONCLUSTERED (Member_ID)
)
;
GO
