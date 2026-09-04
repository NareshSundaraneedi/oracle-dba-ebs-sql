--------------------------------------------------------------------------------
-- File Name       : 03_stuck_workflows.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : Open items with no recent activity (stuck)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Open WF_ITEMS whose latest activity is old — deferred/notified and never progressed.
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
-- QUERY 1: Stuck open items
--------------------------------------------------------------------------------
-- 1. What the query does
--    Open items with begin_date older than &days and still open.
-- 2. Important columns
--    ITEM_TYPE, ITEM_KEY, BEGIN_DATE, USER_KEY.
-- 3. How to interpret the output
--    A PO approval open for 90 days may be a forgotten approver — functional. Thousands stuck the same day is technical.
-- 4. What indicates a problem
--    Mass stuck after Workflow Background Process not running.
-- 5. Recommended DBA action
--    06 background + 04 pending activities.
-- 6. Production cautions
--    Safe. DEFINE days.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE days = 14

SELECT i.item_type, i.item_key, i.user_key, i.begin_date, i.owner_role, i.root_activity
FROM wf_items i
WHERE i.end_date IS NULL
AND i.begin_date < SYSDATE - &days
ORDER BY i.begin_date
FETCH FIRST 100 ROWS ONLY;

PROMPT
PROMPT === End of query: Stuck open items ===
PROMPT

-- End of file
