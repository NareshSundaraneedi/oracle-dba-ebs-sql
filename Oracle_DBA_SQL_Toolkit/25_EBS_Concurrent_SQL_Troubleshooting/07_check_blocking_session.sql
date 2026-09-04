--------------------------------------------------------------------------------
-- File Name       : 07_check_blocking_session.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 7 — blocker for the request session
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- If BLOCKING_SESSION is set, identify the blocker (often an inactive form). Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 7 — blocker for the request session
--------------------------------------------------------------------------------
-- 1. What the query does
--    If BLOCKING_SESSION is set, identify the blocker (often an inactive form).
-- 2. Important columns
--    See SELECT list.
-- 3. How to interpret the output
--    Capture the output into the incident ticket before changing anything.
-- 4. What indicates a problem
--    Missing session or SQL_ID means the program is not in a DB call — check the request log.
-- 5. Recommended DBA action
--    Continue the next numbered script. Do not skip to kill.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
DEFINE sid = 0
DEFINE inst = 1
SELECT w.sid waiter, w.event, w.sql_id, w.blocking_instance, w.blocking_session,
       b.username, b.status, b.module, b.machine, b.program, b.last_call_et, b.sql_id blocker_sql
FROM gv$session w
LEFT JOIN gv$session b ON b.inst_id=NVL(w.blocking_instance,w.inst_id) AND b.sid=w.blocking_session
WHERE w.inst_id=&inst AND w.sid=&sid;

PROMPT
PROMPT === End of query: Step 7 — blocker for the request session ===
PROMPT

-- End of file
