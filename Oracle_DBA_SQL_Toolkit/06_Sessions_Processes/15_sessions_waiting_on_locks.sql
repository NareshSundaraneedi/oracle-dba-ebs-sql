--------------------------------------------------------------------------------
-- File Name       : 15_sessions_waiting_on_locks.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Sessions waiting on enqueue / TX / TM locks
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Quick filter for lock waits. Full chain analysis is folder 10.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Enqueue waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters events like enq:% or waiting on a blocking_session.
-- 2. Important columns
--    SID, EVENT, BLOCKING_SESSION, SQL_ID.
-- 3. How to interpret the output
--    enq: TX - row lock contention is a row lock. enq: TM is usually unindexed FK or table lock.
-- 4. What indicates a problem
--    A tree of waiters behind one inactive Forms session.
-- 5. Recommended DBA action
--    Open 10_Locks_Blocking/01 and /11.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       inst_id,
       sid,
       serial#,
       username,
       module,
       sql_id,
       event,
       seconds_in_wait,
       blocking_session,
       blocking_instance,
       blocking_session_status
FROM   gv$session
WHERE  blocking_session IS NOT NULL
OR     event LIKE 'enq:%'
OR     event LIKE 'cursor: pin%'
ORDER BY blocking_instance, blocking_session, seconds_in_wait DESC;

PROMPT
PROMPT === End of query: Enqueue waiters ===
PROMPT

-- End of file
