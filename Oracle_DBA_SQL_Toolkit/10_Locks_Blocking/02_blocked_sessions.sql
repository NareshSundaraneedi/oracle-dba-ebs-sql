--------------------------------------------------------------------------------
-- File Name       : 02_blocked_sessions.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : List sessions waiting on a blocker
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Waiter side: who is stuck, for how long, on which event and SQL.
--
-- How to identify lock roles:
--   BLOCKER           = session that holds the enqueue and is not waiting on a lock (or is the root)
--   BLOCKED SESSION   = session with BLOCKING_SESSION set or waiting on enq:
--   WAIT EVENT        = typically enq: TX - row lock contention or enq: TM - contention
--   OBJECT            = DBA_OBJECTS via current SQL or V$LOCKED_OBJECT
--   SQL_ID            = waiter and blocker current/prev SQL
--   MACHINE/PROGRAM/MODULE/USERNAME = from GV$SESSION
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Current waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sessions with BLOCKING_SESSION IS NOT NULL.
-- 2. Important columns
--    WAITER SID, EVENT, SECONDS_IN_WAIT, SQL_ID, MODULE, BLOCKER.
-- 3. How to interpret the output
--    SECONDS_IN_WAIT of thousands = business impact. Same SQL_ID on many waiters = one hot row/table.
-- 4. What indicates a problem
--    Order management waiters behind a single APPS form.
-- 5. Recommended DBA action
--    Map MODULE to the form. Use 07_locked_objects for the object.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       w.inst_id,
       w.sid            AS blocked_sid,
       w.serial#        AS blocked_serial,
       w.username,
       w.module,
       w.program,
       w.machine,
       w.sql_id,
       w.event          AS wait_event,
       w.seconds_in_wait,
       w.blocking_instance,
       w.blocking_session,
       w.blocking_session_status
FROM   gv$session w
WHERE  w.blocking_session IS NOT NULL
ORDER BY w.seconds_in_wait DESC;

PROMPT
PROMPT === End of query: Current waiters ===
PROMPT

-- End of file
