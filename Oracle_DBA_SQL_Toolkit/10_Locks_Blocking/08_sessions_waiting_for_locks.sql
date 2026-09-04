--------------------------------------------------------------------------------
-- File Name       : 08_sessions_waiting_for_locks.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : Waiters only, with object and blocker SQL
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Convenience join of waiters to locked objects for a single output
-- used on bridges.
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
-- QUERY 1: Waiters with object names
--------------------------------------------------------------------------------
-- 1. What the query does
--    Waiters plus objects locked by their blocker.
-- 2. Important columns
--    BLOCKED SESSION, WAIT EVENT, OBJECT, BLOCKER, SQL_IDs.
-- 3. How to interpret the output
--    Object list on the blocker may include more than the contended row's table.
-- 4. What indicates a problem
--    Waiters on a critical EBS table (OE_ORDER_HEADERS_ALL, GL_JE_LINES).
-- 5. Recommended DBA action
--    Functional escalation with object name + blocker module.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$LOCKED_OBJECT, DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT
       w.inst_id waiter_inst,
       w.sid waiter_sid,
       w.username waiter_user,
       w.event wait_event,
       w.sql_id waiter_sql,
       w.module waiter_module,
       w.seconds_in_wait,
       b.sid blocker_sid,
       b.username blocker_user,
       b.status blocker_status,
       b.module blocker_module,
       b.sql_id blocker_sql,
       b.machine blocker_machine,
       b.program blocker_program,
       o.owner,
       o.object_name
FROM   gv$session w
JOIN   gv$session b
       ON b.sid = w.blocking_session
      AND b.inst_id = NVL(w.blocking_instance, w.inst_id)
LEFT JOIN gv$locked_object lo
       ON lo.inst_id = b.inst_id AND lo.session_id = b.sid
LEFT JOIN dba_objects o ON o.object_id = lo.object_id
WHERE  w.blocking_session IS NOT NULL
ORDER BY w.seconds_in_wait DESC;

PROMPT
PROMPT === End of query: Waiters with object names ===
PROMPT

-- End of file
