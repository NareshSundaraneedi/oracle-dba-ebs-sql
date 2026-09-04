--------------------------------------------------------------------------------
-- File Name       : 08_long_running_workflow_activities.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : Activities in ACTIVE / DEFERRED for a long time
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Long-running function activities can hold a background process.
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
-- QUERY 1: Long active/deferred
--------------------------------------------------------------------------------
-- 1. What the query does
--    WF_ITEM_ACTIVITY_STATUSES with old execution_time still not COMPLETE.
-- 2. Important columns
--    ITEM_TYPE, ITEM_KEY, STATUS, AGE_HOURS.
-- 3. How to interpret the output
--    ACTIVE for hours on a function activity may be a stuck SQL — find the session via module.
-- 4. What indicates a problem
--    One item_key ACTIVE since yesterday on a custom function.
-- 5. Recommended DBA action
--    25-style session hunt with MODULE like WFWK or the package name.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT item_type, item_key, activity_status,
       ROUND((SYSDATE-execution_time)*24,1) hours_since_exec,
       activity_result_code, assigned_user
FROM wf_item_activity_statuses
WHERE activity_status IN ('ACTIVE','DEFERRED','NOTIFIED')
AND execution_time < SYSDATE-1
ORDER BY execution_time
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: Long active/deferred ===
PROMPT

-- End of file
