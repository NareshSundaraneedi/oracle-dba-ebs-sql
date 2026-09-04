--------------------------------------------------------------------------------
-- File Name       : 11_blocking_tree.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : Formatted blocking tree for incident bridges
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Single output designed to paste into a ticket. Difference vs
-- 03: presentation-focused with blocker/blocked labels.
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
-- QUERY 1: Pretty blocking tree
--------------------------------------------------------------------------------
-- 1. What the query does
--    Hierarchical formatted output.
-- 2. Important columns
--    TREE, ROLE, WAIT_EVENT, OBJECT hint via module/sql.
-- 3. How to interpret the output
--    Root line is BLOCKER. Indented lines are BLOCKED SESSION.
-- 4. What indicates a problem
--    Any tree during business hours on order/finance modules.
-- 5. Recommended DBA action
--    Escalate with this output plus 07 objects.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       LPAD('+- ', 3*(LEVEL-1), ' ') ||
       CASE WHEN LEVEL = 1 THEN 'BLOCKER ' ELSE 'BLOCKED ' END ||
       username || ' inst=' || inst_id || ' sid=' || sid || ',' || serial# ||
       ' status=' || status ||
       ' event=' || event ||
       ' sql=' || NVL(sql_id,'-') ||
       ' module=' || NVL(module,'-') ||
       ' machine=' || NVL(machine,'-') ||
       ' program=' || NVL(program,'-') AS tree
FROM   gv$session
START WITH blocking_session IS NULL
AND (inst_id, sid) IN (
       SELECT NVL(blocking_instance, inst_id), blocking_session
       FROM   gv$session WHERE blocking_session IS NOT NULL)
CONNECT BY PRIOR sid = blocking_session
AND PRIOR inst_id = NVL(blocking_instance, inst_id);

PROMPT
PROMPT === End of query: Pretty blocking tree ===
PROMPT

-- End of file
