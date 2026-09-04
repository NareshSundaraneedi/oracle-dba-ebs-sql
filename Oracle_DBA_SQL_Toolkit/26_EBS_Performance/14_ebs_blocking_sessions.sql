--------------------------------------------------------------------------------
-- File Name       : 14_ebs_blocking_sessions.sql
-- Category        : 26_EBS_Performance
-- Purpose         : Blocking chains involving APPS
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Folder 10 filtered to APPS usernames.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: APPS blockers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Waiters/blockers where either side is APPS.
-- 2. Important columns
--    BLOCKER, WAITER, MODULES.
-- 3. How to interpret the output
--    Inactive APPS blocker = forgotten form.
-- 4. What indicates a problem
--    Order Entry waiters behind one APPS sid.
-- 5. Recommended DBA action
--    10 + user contact.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT b.sid blocker, b.status blocker_status, b.module blocker_module, b.last_call_et,
       w.sid waiter, w.event, w.module waiter_module, w.sql_id, w.seconds_in_wait
FROM gv$session w JOIN gv$session b ON b.sid=w.blocking_session AND b.inst_id=NVL(w.blocking_instance,w.inst_id)
WHERE w.username='APPS' OR b.username='APPS'
ORDER BY w.seconds_in_wait DESC;

PROMPT
PROMPT === End of query: APPS blockers ===
PROMPT

-- End of file
