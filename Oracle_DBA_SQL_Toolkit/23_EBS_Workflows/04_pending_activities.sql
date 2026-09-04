--------------------------------------------------------------------------------
-- File Name       : 04_pending_activities.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : Activities in DEFERRED / NOTIFIED / WAITING
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFERRED is what Workflow Background Process picks up. If DEFERRED piles up, the background request is not running or is too slow.
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
-- QUERY 1: Pending activity statuses
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group WF_ITEM_ACTIVITY_STATUSES by activity_status.
-- 2. Important columns
--    ACTIVITY_STATUS, CNT.
-- 3. How to interpret the output
--    DEFERRED high = background engine backlog. NOTIFIED high can be normal (human approvals).
-- 4. What indicates a problem
--    DEFERRED in the tens of thousands.
-- 5. Recommended DBA action
--    Run Workflow Background Process for that item type with Process Deferred Yes. Check 06.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT activity_status, COUNT(*) cnt
FROM wf_item_activity_statuses
GROUP BY activity_status
ORDER BY cnt DESC;

SELECT item_type, COUNT(*) deferred_cnt
FROM wf_item_activity_statuses
WHERE activity_status = 'DEFERRED'
GROUP BY item_type
ORDER BY deferred_cnt DESC;

PROMPT
PROMPT === End of query: Pending activity statuses ===
PROMPT

-- End of file
