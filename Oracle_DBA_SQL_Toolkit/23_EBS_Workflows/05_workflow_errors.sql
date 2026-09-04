--------------------------------------------------------------------------------
-- File Name       : 05_workflow_errors.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : WF_ITEMS / error monitor (WF_ITEM_ACTIVITY_STATUSES error columns)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Error name histogram for the last week.
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
-- QUERY 1: Error names
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group errors.
-- 2. Important columns
--    ERROR_NAME, CNT, SAMPLE_MSG.
-- 3. How to interpret the output
--    Repeated WFER_... or mailer errors point to infrastructure.
-- 4. What indicates a problem
--    New error name after a patch.
-- 5. Recommended DBA action
--    MOS the error_name. Fix mailer / agent if notification related.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT error_name, COUNT(*) cnt,
       MAX(SUBSTR(error_message,1,120)) sample_msg
FROM wf_item_activity_statuses
WHERE activity_status='ERROR'
AND execution_time > SYSDATE-7
GROUP BY error_name
ORDER BY cnt DESC;

PROMPT
PROMPT === End of query: Error names ===
PROMPT

-- End of file
