--------------------------------------------------------------------------------
-- File Name       : 22_ash_by_sql_id.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : ASH filtered to one SQL_ID
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Session-level timeline for a known SQL_ID (from a concurrent
-- request or V$SQL).
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
-- QUERY 1: ASH rows for &sql_id
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters ASH by SQL_ID.
-- 2. Important columns
--    SAMPLE_TIME, SESSION_ID, EVENT, WAIT_CLASS, BLOCKING_SESSION.
-- 3. How to interpret the output
--    See if the SQL is on CPU, I/O, or blocked over time.
-- 4. What indicates a problem
--    Most samples on a lock event.
-- 5. Recommended DBA action
--    10_Locks_Blocking.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on GV_$ACTIVE_SESSION_HISTORY
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs
DEFINE minutes = 60

SELECT
       inst_id,
       session_id,
       session_serial#,
       sql_id,
       sql_plan_hash_value,
       session_state,
       NVL(event,'ON CPU') event,
       wait_class,
       blocking_session,
       module,
       machine,
       sample_time
FROM   gv$active_session_history
WHERE  sql_id = '&sql_id'
AND    sample_time > SYSDATE - &minutes/1440
ORDER BY sample_time;

PROMPT
PROMPT === End of query: ASH rows for &sql_id ===
PROMPT

-- End of file
