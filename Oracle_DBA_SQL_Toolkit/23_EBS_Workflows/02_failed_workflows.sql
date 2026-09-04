--------------------------------------------------------------------------------
-- File Name       : 02_failed_workflows.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : Errored workflow activities (WF_ITEM_ACTIVITY_STATUSES)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ACTIVITY_STATUS ERROR. These need the error notification / admin to retry or abort.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Errored activities
--------------------------------------------------------------------------------
-- 1. What the query does
--    WF_ITEM_ACTIVITY_STATUSES status ERROR last 7 days.
-- 2. Important columns
--    ITEM_TYPE, ITEM_KEY, ACTIVITY, ERROR_NAME, ERROR_MESSAGE.
-- 3. How to interpret the output
--    ERROR_NAME often has the exception. ERROR_STACK is in WF_ITEM_ACTIVITY_STATUSES too (column names vary — ERROR_MESSAGE is typical).
-- 4. What indicates a problem
--    POAPPRV / REQAPPRV mass errors after a mailer or AMG issue.
-- 5. Recommended DBA action
--    Workflow Administrator. Do not DELETE wf tables.
-- 6. Production cautions
--    Safe. Do not update STATUS via SQL.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT ias.item_type, ias.item_key, ias.process_activity,
       ias.activity_status, ias.activity_result_code,
       ias.error_name, SUBSTR(ias.error_message,1,200) error_message,
       ias.execution_time
FROM wf_item_activity_statuses ias
WHERE ias.activity_status = 'ERROR'
AND NVL(ias.notification_id,0) = NVL(ias.notification_id,0)
AND ias.execution_time > SYSDATE-7
ORDER BY ias.execution_time DESC
FETCH FIRST 100 ROWS ONLY;

PROMPT
PROMPT === End of query: Errored activities ===
PROMPT

-- End of file
