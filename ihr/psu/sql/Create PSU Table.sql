USE [IHR_RAP];
GO


-- /**
--  * The following Scalar function allows the insertion of the member "group" key, 
--  * where "group" refers to the combination of MemberFirstName, MemberLastName, 
--  * MemberZipCd, to be used in identifying Members, not at the row level, but at 
--  * the member level. For example, if CountOf_LOB > 1 (LOB = Lines of Business),
--  * then you should be able to get the distinct count of members across all LOB 
--  * by counting DISTINCT Member_Key.
--  */
-- CREATE FUNCTION stage.GenerateMemberKey
-- (
--     @Row_ID           BIGINT
--   , @MemberFirstName  VARCHAR(50)
--   , @MemberLastName   VARCHAR(50)
--   , @Member_DOB       DATE
--   , @MemberZipCd      VARCHAR(5)
-- )
-- RETURNS BIGINT
-- AS
-- BEGIN

--     RETURN 
--     (
--         SELECT a.dr
--         FROM ( 
--                 SELECT rn = ROW_NUMBER() OVER (PARTITION BY First_Name, Last_Name ORDER BY First_Name, Last_Name, LOB)
--                      , dr = DENSE_RANK() OVER (ORDER BY First_Name, Last_Name)
--                      , Row_Id
--                      , MemberFirstName
--                      , MemberLastName
--                      , Member_DOB
--                      , MemberZipCd
--                      , LOB
--                 FROM superuser_memberkey 
--              ) a
--         WHERE a.rn = 1
--     )
-- END
-- ;
-- GO 



CREATE TABLE [IHR_RAP].[stage].[PSU_Combined] 
(   Row_ID                  BIGINT IDENTITY(1, 1)
  , Primary_Key             BIGINT IDENTITY(10000000000, 1)  NOT NULL  PRIMARY KEY
--  , Member_Key  AS stage.GenerateMemberKey(MemberFirstName, MemberLastName, Member_DOB, MemberZipCd)
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
  , CS_file_origin          VARCHAR(50)                          NULL
  , MemberGender            VARCHAR(1)                           NULL
  , HCE_PredictiveScore     DECIMAL(10,2)                        NULL
  , Is_PSU                  BIT                                  NULL
  , PSU_Score_Cutoff        DECIMAL(10,2)                        NULL
  , ACO_Flag                BIT                                  NULL
  , ACO_Name                VARCHAR(255)                         NULL
  , ExchangeInd             VARCHAR(1)                           NULL
  , CustomerSegmentNumber   VARCHAR(7)                           NULL
  , GroupName               VARCHAR(255)                         NULL
  , EI_Referral             VARCHAR(10)                          NULL
  , MarketRollup            VARCHAR(255)                         NULL
  , MarketSegment           VARCHAR(3)                           NULL
  , MemberZipCd             VARCHAR(5)                           NULL
  , MemberZipPlus4Cd        VARCHAR(4)                           NULL
  , MemberCityName          VARCHAR(255)                         NULL
  , MemberCounty            VARCHAR(255)                         NULL
  , MemberState             VARCHAR(2)                           NULL
  , MR_ContractNumber       VARCHAR(10)                          NULL
  , MR_PBP                  VARCHAR(3)                           NULL
  , MR_Product              VARCHAR(50)                          NULL
  , MR_ProgramName          VARCHAR(50)                          NULL
  , GI                      VARCHAR(5)                           NULL
  , CongestiveHeartFailure  INT                                  NULL
  , Diabetes                INT                                  NULL
  , EndStageRenal           INT                                  NULL
  , TCM_eng                 INT                                  NULL
  , HRCM_eng                INT                                  NULL
  , AI_eng                  INT                                  NULL
  , Any_Optum_Program       INT                                  NULL
  , RCT                     INT                                  NULL
  , LoadDate_Py             DATE                                 NULL
  , CountOf_LOB             INT                                  NULL
  , CountOfFiles            INT                                  NULL
  , FileName                VARCHAR(255)                         NULL
  , InsertDate              DATE                                 NULL
  , LastModifiedDate        DATE                                 NULL
  , DropDate                DATE                                 NULL
  , SuperUser_Status        VARCHAR(20)                          NULL
  , SuperUser_SubStatus     VARCHAR(20)                          NULL

  -- This creates a non-clustered index on (Member_ID)
  , INDEX IX_PSU_Combined_Member_ID NONCLUSTERED (Member_ID)
)
;
GO
