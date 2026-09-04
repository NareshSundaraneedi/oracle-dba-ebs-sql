--------------------------------------------------------------------------------
-- File Name       : 01_blocking_sessions.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : List sessions that are blocking others right now
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- First script to run on a locking incident. Shows the blocker
-- identity so you can call the user or decide on a disconnect.
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
-- QUERY 1: Current blockers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Finds sessions whose SID is referenced as BLOCKING_SESSION.
-- 2. Important columns
--    BLOCKER SID/SERIAL/INST, USERNAME, MODULE, STATUS, SQL_ID, MACHINE, PROGRAM, EVENT.
-- 3. How to interpret the output
--    INACTIVE blocker + ACTIVE waiters = forgotten Forms session (classic EBS).
-- 4. What indicates a problem
--    A blocker idle for hours with many waiters.
-- 5. Recommended DBA action
--    Contact the user. Generate disconnect (06/17) if policy allows. Do not kill blindly if it is a payroll post.
-- 6. Production cautions
--    Safe to query. Killing is destructive — not executed.
-- 7. Required privileges
--    SELECT on GV_$SESSION
-- EBS relevance  : Critical for EBS
--------------------------------------------------------------------------------
SELECT DISTINCT
       b.inst_id              AS blocker_inst,
       b.sid                  AS blocker_sid,
       b.serial#              AS blocker_serial,
       b.username             AS blocker_user,
       b.status               AS blocker_status,
       b.event                AS blocker_event,
       b.sql_id               AS blocker_sql_id,
       b.prev_sql_id          AS blocker_prev_sql,
       b.module               AS blocker_module,
       b.program              AS blocker_program,
       b.machine              AS blocker_machine,
       b.osuser               AS blocker_osuser,
       b.last_call_et         AS blocker_last_call_et,
       COUNT(*) OVER (PARTITION BY b.inst_id, b.sid) AS waiter_count
FROM   gv$session w
JOIN   gv$session b
       ON b.inst_id = NVL(w.blocking_instance, w.inst_id)
      AND b.sid     = w.blocking_session
WHERE  w.blocking_session IS NOT NULL
ORDER BY waiter_count DESC, b.inst_id, b.sid;

PROMPT
PROMPT === End of query: Current blockers ===
PROMPT

-- End of file
