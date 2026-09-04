--------------------------------------------------------------------------------
-- File Name       : 03_find_sql_id.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 3 — capture SQL_ID (current and previous)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SQL_ID / PREV_SQL_ID / SQL_CHILD_NUMBER for the session. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 3 — capture SQL_ID (current and previous)
--------------------------------------------------------------------------------
-- 1. What the query does
--    SQL_ID / PREV_SQL_ID / SQL_CHILD_NUMBER for the session.
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
SELECT inst_id, sid, serial#, sql_id, sql_child_number, prev_sql_id, event, last_call_et, blocking_session
FROM gv$session WHERE inst_id=&inst AND sid=&sid;

PROMPT
PROMPT === End of query: Step 3 — capture SQL_ID (current and previous) ===
PROMPT

-- End of file
