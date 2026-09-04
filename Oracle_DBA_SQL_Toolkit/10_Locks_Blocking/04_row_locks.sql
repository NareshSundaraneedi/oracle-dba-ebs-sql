--------------------------------------------------------------------------------
-- File Name       : 04_row_locks.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : Row-level TX lock waiters (enq: TX - row lock contention)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Filters to the classic row-lock event. Use when the wait event
-- is specifically row lock contention, not TM.
--
-- How to identify lock roles:
--   BLOCKER           = session that holds the enqueue and is not waiting on a lock (or is the root)
--   BLOCKED SESSION   = session with BLOCKING_SESSION set or waiting on enq:
--   WAIT EVENT        = typically enq: TX - row lock contention or enq: TM - contention
--   OBJECT            = DBA_OBJECTS via current SQL or V$LOCKED_OBJECT
--   SQL_ID            = waiter and blocker current/prev SQL
--   MACHINE/PROGRAM/MODULE/USERNAME = from GV$SESSION
-- TX row lock: waiter wants a row held by an uncommitted DML.
-- P1/P2/P3 decode: usn/slot/seq of the undo for the holder (advanced).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: TX row lock waiters and holders
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters EVENT = enq: TX - row lock contention and maps blockers.
-- 2. Important columns
--    WAITER, BLOCKER, SQL_ID, MODULE, SECONDS.
-- 3. How to interpret the output
--    Same table/row usually means two forms on the same document.
-- 4. What indicates a problem
--    Many waiters, one blocker on a setup table (single-row bottleneck).
-- 5. Recommended DBA action
--    User communication. Application design for hot rows.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       w.inst_id, w.sid waiter_sid, w.serial#, w.username waiter_user,
       w.module, w.sql_id waiter_sql, w.seconds_in_wait,
       w.event,
       b.inst_id blocker_inst, b.sid blocker_sid, b.serial# blocker_serial,
       b.username blocker_user, b.status blocker_status,
       b.module blocker_module, b.sql_id blocker_sql, b.prev_sql_id,
       b.machine, b.program
FROM   gv$session w
JOIN   gv$session b
       ON b.sid = w.blocking_session
      AND b.inst_id = NVL(w.blocking_instance, w.inst_id)
WHERE  w.event = 'enq: TX - row lock contention'
ORDER BY w.seconds_in_wait DESC;

PROMPT
PROMPT === End of query: TX row lock waiters and holders ===
PROMPT

-- End of file
