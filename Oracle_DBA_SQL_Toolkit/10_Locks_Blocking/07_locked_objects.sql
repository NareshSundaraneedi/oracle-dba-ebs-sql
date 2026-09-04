--------------------------------------------------------------------------------
-- File Name       : 07_locked_objects.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : Objects currently locked (V$LOCKED_OBJECT)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Maps sessions to locked objects. Essential for telling the
-- functional team 'which document/table'.
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
-- QUERY 1: Locked objects with session identity
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins V$LOCKED_OBJECT to sessions and DBA_OBJECTS.
-- 2. Important columns
--    OWNER, OBJECT_NAME, LOCKED_MODE, USERNAME, MODULE, MACHINE, SQL_ID.
-- 3. How to interpret the output
--    LOCKED_MODE 3 = row exclusive (DML). Mode 6 = exclusive.
-- 4. What indicates a problem
--    A setup table locked exclusively.
-- 5. Recommended DBA action
--    Identify the blocker via 01 using the SESSION_ID.
-- 6. Production cautions
--    Safe. RAC: use GV$LOCKED_OBJECT.
-- 7. Required privileges
--    SELECT on GV_$LOCKED_OBJECT, GV_$SESSION, DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT
       lo.inst_id,
       lo.session_id,
       s.serial#,
       s.username,
       s.status,
       s.module,
       s.program,
       s.machine,
       s.sql_id,
       s.event,
       lo.locked_mode,
       o.owner,
       o.object_name,
       o.object_type,
       lo.os_user_name
FROM   gv$locked_object lo
JOIN   dba_objects o ON o.object_id = lo.object_id
JOIN   gv$session s ON s.inst_id = lo.inst_id AND s.sid = lo.session_id
ORDER BY o.owner, o.object_name, lo.inst_id, lo.session_id;

PROMPT
PROMPT === End of query: Locked objects with session identity ===
PROMPT

-- End of file
