USE [IHR_RAP];
GO


CREATE TABLE [IHR].[IHR_Incidents]
(   
    [IN_ID]                          [varchar](12)  NOT NULL  PRIMARY KEY
  , [IN_CATEGORY]                    [varchar](max)     NULL
  , [OPEN_TIME]                      [datetime]         NULL
  , [UH_OPENED_BY_ID]                [varchar](max)     NULL
  , [PRIORITY_CODE]                  [varchar](max)     NULL
  , [UPDATE_TIME]                    [datetime]         NULL
  , [ASSIGNMENT]                     [varchar](max)     NULL
  , [STATUS]                         [varchar](max)     NULL
  , [CLOSE_TIME]                     [datetime]         NULL
  , [UH_CLOSED_BY_ID]                [varchar](max)     NULL
  , [RESOLUTION_CODE]                [varchar](max)     NULL
  , [LOGICAL_NAME]                   [varchar](max)     NULL
  , [ACTION]                         [varchar](max)     NULL
  , [RESOLUTION]                     [varchar](max)     NULL
  , [ASSIGNEE_NAME]                  [varchar](max)     NULL
  , [UPDATE_ACTION]                  [varchar](max)     NULL
  , [BRIEF_DESCRIPTION]              [varchar](max)     NULL
  , [PROBLEM_STATUS]                 [varchar](max)     NULL
  , [SUBCATEGORY]                    [varchar](max)     NULL
  , [PRODUCT_TYPE]                   [varchar](max)     NULL
  , [PROBLEM_TYPE]                   [varchar](max)     NULL
  , [ALTERNATE_PHONE]                [varchar](max)     NULL
  , [AFFECTED_ITEM]                  [varchar](max)     NULL
  , [UH_ASSIGNEE_FULL_NAME]          [varchar](max)     NULL
  , [UH_CALLBACK_CONTACT]            [varchar](max)     NULL
  , [UH_CALLBACK_TYPE]               [varchar](max)     NULL
  , [UH_SPARK_INCIDENT]              [bigint]           NULL
  , [UH_NEEDED_BY_TIME]              [datetime]         NULL
  , [UH_ALTERNATE_FULL_NAME]         [varchar](max)     NULL
  , [UH_ALTERNATE_PHONE]             [varchar](max)     NULL
  , [UH_INCIDENT_TYPE]               [varchar](max)     NULL
  , [UH_PLANNED_FINISH]              [datetime]         NULL
  , [UH_WORKAROUND]                  [varchar](max)     NULL
  , [UH_ASSIGNMENT_COUNTER]          [bigint]           NULL
  , [UH_IT_ESCALATION]               [varchar](max)     NULL
  , [UH_RESTORATION_GOAL]            [bigint]           NULL
  , [UH_IT_EXEC]                     [varchar](max)     NULL
  , [UH_RESTORE_TIME]                [datetime]         NULL
  , [UH_PENDING_CLOSED]              [datetime]         NULL
  , [UH_ICT_CONTACT]                 [varchar](max)     NULL
  , [UH_ESS_TICKET]                  [bigint]           NULL
  , [UH_ALERT]                       [varchar](max)     NULL
  , [UH_REFERENCE_NUMBER_1]          [varchar](max)     NULL
  , [UH_REFERENCE_NUMBER_2]          [varchar](max)     NULL
  , [UH_CLASSIFICATION]              [varchar](max)     NULL
  , [UH_PENDING_CLOSED_ID]           [varchar](max)     NULL
  , [UH_WORKFROM]                    [varchar](max)     NULL
  , [UH_REQUEST_PERSON]              [varchar](max)     NULL
  , [UH_REQUEST_PERSON_NAME]         [varchar](max)     NULL
  , [UH_REQUEST_PERSON_NUMBER]       [varchar](max)     NULL
  , [UH_ESS_ERRORMSG]                [varchar](max)     NULL
  , [UH_ESS_STEPSTAKEN]              [varchar](max)     NULL
  , [UH_ESS_ISSUETIME]               [varchar](max)     NULL
  , [UH_LOGICAL_NAME]                [varchar](max)     NULL
  , [UH_AFFECTED_ITEM]               [varchar](max)     NULL
  , [UH_EXECUTIVE_ARRAY]             [varchar](max)     NULL
  , [UH_UNDEFINED_CI1]               [varchar](max)     NULL
  , [UH_MISSED_SLA]                  [varchar](max)     NULL
  , [UH_REOPENED_COUNTER]            [bigint]           NULL
  , [UH_REFERENCE_NUMBER_3]          [varchar](max)     NULL
  , [UH_REFERENCE_NUMBER_4]          [varchar](max)     NULL
  , [UH_REFERENCE_NUMBER_5]          [varchar](max)     NULL
  , [UH_REFERENCE_NUMBER_6]          [varchar](max)     NULL
  , [UPDATE_ACTION_ESS]              [varchar](max)     NULL
  , [UH_ESS_APP_NOTWORKING]          [varchar](max)     NULL
  , [UH_UNDEFINED_SERVICE]           [varchar](max)     NULL
  , [UH_MACHINE_NAME]                [varchar](max)     NULL
  , [UH_LOCK_RECORD]                 [varchar](max)     NULL
  , [UH_USC_KNOWLEDGE]               [varchar](max)     NULL
  , [UH_CSS_KNOWLEDGE]               [varchar](max)     NULL
  , [UH_START_TIME]                  [varchar](max)     NULL
  , [UH_RESTORED_DURATION]           [float]            NULL
  , [EVENT_ID]                       [varchar](max)     NULL
  , [TOTAL_ADTM]                     [varchar](max)     NULL
  , [UH_CAUSED_BY_CHANGE]            [bigint]           NULL
  , [UH_UPDATED_BY]                  [varchar](max)     NULL
  , [UH_VALIDATED]                   [bigint]           NULL
  , [UH_START_INVOLVEMENT]           [varchar](max)     NULL
  , [UH_INVOLVEMENT_END]             [varchar](max)     NULL
  , [UH_DIAGNOSIS_COMPLETE]          [varchar](max)     NULL
  , [UH_RESTORATION]                 [varchar](max)     NULL
  , [UH_WAR_ROOM_END]                [varchar](max)     NULL
  , [UH_NUMBER_ISSUE]                [varchar](max)     NULL
  , [TEMPLATE_NAME]                  [varchar](max)     NULL
  , [SLA_MULTIPLIER]                 [bigint]           NULL
  , [SLA_MULTIPLIER_XWT]             [float]            NULL
  , [RESTORED_DURATION_XWT]          [float]            NULL
  , [ATTACHMENTS]                    [bigint]           NULL
  , [CUSTOMER_IMPACT]                [varchar](max)     NULL
  , [AFF_SRV_CONCAT]                 [varchar](max)     NULL
  , [AFF_SRV_CONCAT_UCMDB]           [varchar](max)     NULL
  , [MAN_SRV_CONCAT]                 [varchar](max)     NULL
  , [MAN_SRV_CONCAT_UCMDB]           [varchar](max)     NULL
  , [REL_SRV_CONCAT]                 [varchar](max)     NULL
  , [REL_SRV_CONCAT_UCMDB]           [varchar](max)     NULL
  , [UH_HIGH_PRIORITY_SVC_IMPACT]    [varchar](max)     NULL
  , [UH_ISSUE_TYPE]                  [varchar](max)     NULL
  , [UH_USC_PRODUCT]                 [varchar](max)     NULL
  , [UH_GL_CODE]                     [varchar](max)     NULL
  , [COMPANY]                        [varchar](max)     NULL
  , [UH_UCC_MANAGED]                 [varchar](max)     NULL
  , [UH_SERVICE_IMPACT]              [varchar](max)     NULL
  , [UH_SEC_INC_CNT]                 [bigint]           NULL
  , [UH_SVC_CMPLNT_CNT]              [bigint]           NULL
  , [UH_PLATFORM_TYPE]               [varchar](max)     NULL
  , [UH_CONNECTION_TYPE]             [varchar](max)     NULL
  , [UH_ESS_COMMENTS]                [varchar](max)     NULL
  , [UH_SET_DEADLINE]                [datetime]         NULL
  , [UH_ADTM_VAL_COMM]               [varchar](max)     NULL
  , [UH_SLA_GROUP]                   [varchar](max)     NULL
  , [LIABLE_ADTM]                    [varchar](max)     NULL
  , [UH_EXTERNAL_CLIENT_UPDATE]      [varchar](max)     NULL
  , [UH_CUSTOMER_ESCALATION]         [varchar](max)     NULL
  , [UH_RESPONSE_DEADLINE]           [datetime]         NULL
  , [UH_RESPONSE_GOAL_ACHIEVED]      [varchar](max)     NULL
  , [UH_RESPONSE_TIME]               [datetime]         NULL
  , [UH_RESOURCE_ID]                 [varchar](max)     NULL
  , [SN_CONTACT_TYPE]                [varchar](max)     NULL
  , [SN_SYS_ID]                      [varchar](max)     NULL
  , [SN_PARENT_ID]                   [varchar](max)     NULL
  , [SN_PROBLEM_ID]                  [varchar](max)     NULL
  , [SN_CLASSIFICATION_2]            [varchar](max)     NULL
  , [SN_CLASSIFICATION_3]            [varchar](max)     NULL
  , [SN_WR_RESTORE_TIME]             [varchar](max)     NULL
  , [SN_WG_SYS_ID]                   [varchar](max)     NULL
  , [SN_KNOWLEDGE_ID_FLAG]           [bigint]           NULL
  , [SN_CREATED_IN_BUS_HRS_FLAG]     [varchar](max)     NULL
  , [SN_WORK_IN_PROGRESS_ON]         [datetime]         NULL
  , [SN_RESTORED_ON]                 [varchar](max)     NULL
  , [SN_WAITING_CLIENT_ON]           [datetime]         NULL
  , [SN_WAITING_IT_ON]               [datetime]         NULL
  , [SN_CANCELLED_ON]                [varchar](max)     NULL
  , [SN_RESPONDED_ON]                [datetime]         NULL
  , [SN_CTS_OUTAGE_MINUTES]          [bigint]           NULL
  , [SN_FAILED_SERVICE]              [varchar](max)     NULL
  , [SN_POLARIS_PROGRAM]             [bigint]           NULL
  , [SN_SUBCATEGORY2]                [varchar](max)     NULL
  , [SN_CAUSED_BY_CHANGE]            [varchar](max)     NULL
  , [SN_CBA_ADTM]                    [varchar](max)     NULL
  , [SN_REOPEN_CALLER_CNT]           [bigint]           NULL
  , [SN_ALT_EMAIL_ADD]               [varchar](max)     NULL
  , [SN_ISSUE_RESOLVED_TICKET_ONLY]  [bigint]           NULL
  , [SN_USER_BUSSINESS_IMPACT]       [varchar](max)     NULL
  , [Date_Ingested]                  [datetime]         NULL

  , INDEX IX_MDE_HICN_NUM NONCLUSTERED (MBR_HICN_NUM)
)
;
GO



