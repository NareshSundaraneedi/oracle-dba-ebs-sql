--------------------------------------------------------------------------------
-- File Name       : 03_blocking_chains.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : Assemble blocker→waiter chains including multi-level
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows A blocks B blocks C. You must treat the root, not the middle.
--
-- How to identify lock roles:
--   BLOCKER           = session that holds the enqueue and is not waiting on a lock (or is the root)
--   BLOCKED SESSION   = session with BLOCKING_SESSION set or waiting on enq:
--   WAIT EVENT        = typically enq: TX - row lock contention or enq: TM - contention
--   OBJECT            = DBA_OBJECTS via current SQL or V$LOCKED_OBJECT
--   SQL_ID            = waiter and blocker current/prev SQL
--   MACHINE/PROGRAM/MODULE/USERNAME = from GV$SESSION
-- Difference vs 11_blocking_tree.sql: this is a flat pair list plus a CONNECT BY tree in one file; 11 is a formatted tree only.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Lock chains
--------------------------------------------------------------------------------
-- 1. What the query does
--    Hierarchical query on GV$SESSION blocking columns.
-- 2. Important columns
--    CHAIN, LEVEL, ROOT_BLOCKER, WAIT_EVENT.
-- 3. How to interpret the output
--    LEVEL 1 is the root blocker. Highest LEVEL is the tail waiter.
-- 4. What indicates a problem
--    A long chain — killing a middle session just shifts the wait.
-- 5. Recommended DBA action
--    Act on the root blocker only.
-- 6. Production cautions
--    Safe. CONNECT BY can be messy with RAC; uses inst:sid keys.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       LPAD(' ', 2*(LEVEL-1)) || inst_id || ':' || sid || ' ' || username || ' ' || status AS chain,
       LEVEL,
       CONNECT_BY_ISLEAF AS is_leaf,
       event AS wait_event,
       sql_id,
       module,
       machine,
       program,
       seconds_in_wait
FROM   gv$session
WHERE  blocking_session IS NOT NULL
OR     (inst_id, sid) IN (
         SELECT NVL(blocking_instance, inst_id), blocking_session
         FROM   gv$session
         WHERE  blocking_session IS NOT NULL
       )
START WITH blocking_session IS NULL
AND (inst_id, sid) IN (
         SELECT NVL(blocking_instance, inst_id), blocking_session
         FROM   gv$session
         WHERE  blocking_session IS NOT NULL
       )
CONNECT BY blocking_session = PRIOR sid
AND        NVL(blocking_instance, inst_id) = PRIOR inst_id;

PROMPT
PROMPT === End of query: Lock chains ===
PROMPT

-- End of file
