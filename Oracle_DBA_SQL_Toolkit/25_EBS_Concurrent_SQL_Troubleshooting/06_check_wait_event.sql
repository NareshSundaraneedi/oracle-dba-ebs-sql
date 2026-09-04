--------------------------------------------------------------------------------
-- File Name       : 06_check_wait_event.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 6 — current and session wait events
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- What the session is waiting on now and cumulatively. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 6 — current and session wait events
--------------------------------------------------------------------------------
-- 1. What the query does
--    What the session is waiting on now and cumulatively.
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
SELECT event, wait_class, state, seconds_in_wait, p1text, p1, p2text, p2
FROM gv$session WHERE inst_id=&inst AND sid=&sid;
SELECT event, total_waits, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$session_event WHERE inst_id=&inst AND sid=&sid AND wait_class<>'Idle'
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: Step 6 — current and session wait events ===
PROMPT

-- End of file
