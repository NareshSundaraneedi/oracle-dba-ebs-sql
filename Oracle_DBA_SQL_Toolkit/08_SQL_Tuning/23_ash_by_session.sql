--------------------------------------------------------------------------------
-- File Name       : 23_ash_by_session.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : ASH for one SID/SERIAL
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Used when you already have the Oracle session for a concurrent
-- request or Forms user.
--
-- LICENSING: Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ASH for one session
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters ASH by session_id and inst_id.
-- 2. Important columns
--    SAMPLE_TIME, SQL_ID, EVENT.
-- 3. How to interpret the output
--    SQL_ID changing over time is a Forms session doing many statements. One SQL_ID stuck is a long call.
-- 4. What indicates a problem
--    Same SQL_ID for an hour on one event.
-- 5. Recommended DBA action
--    25_EBS master troubleshooter.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on GV_$ACTIVE_SESSION_HISTORY
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE inst = 1
DEFINE sid  = 123
DEFINE minutes = 60

SELECT sample_time, sql_id, sql_plan_hash_value, session_state,
       NVL(event,'ON CPU') event, wait_class, blocking_session, p1, p2, p3
FROM   gv$active_session_history
WHERE  inst_id = &inst
AND    session_id = &sid
AND    sample_time > SYSDATE - &minutes/1440
ORDER BY sample_time;

PROMPT
PROMPT === End of query: ASH for one session ===
PROMPT

-- End of file
