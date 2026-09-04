--------------------------------------------------------------------------------
-- File Name       : 02_active_sessions.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Sessions currently ACTIVE (on CPU or waiting)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ACTIVE means the session is inside a database call. This is the
-- first view during a 'database is slow' call. Pair with wait event.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Active user sessions
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters GV$SESSION STATUS=ACTIVE TYPE=USER.
-- 2. Important columns
--    SID, SQL_ID, EVENT, WAIT_CLASS, SECONDS_IN_WAIT, MODULE.
-- 3. How to interpret the output
--    Many sessions on the same EVENT is a system problem. One session on CPU with high LAST_CALL_ET is a heavy SQL.
-- 4. What indicates a problem
--    Dozens of ACTIVE sessions on enq: TX or log file sync.
-- 5. Recommended DBA action
--    Follow 09_Wait_Events and 10_Locks_Blocking based on EVENT.
-- 6. Production cautions
--    Safe. On RAC always use GV$.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       inst_id,
       sid,
       serial#,
       username,
       machine,
       program,
       module,
       action,
       sql_id,
       prev_sql_id,
       event,
       wait_class,
       state,
       seconds_in_wait,
       last_call_et,
       blocking_session,
       blocking_instance
FROM   gv$session
WHERE  status = 'ACTIVE'
AND    type   = 'USER'
ORDER BY last_call_et DESC;

PROMPT
PROMPT === End of query: Active user sessions ===
PROMPT

-- End of file
