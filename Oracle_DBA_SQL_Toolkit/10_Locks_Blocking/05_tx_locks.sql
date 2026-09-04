--------------------------------------------------------------------------------
-- File Name       : 05_tx_locks.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : All TX enqueue modes (row lock, ITL, index contention)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Do not treat every TX wait as a missing COMMIT.
--
-- enq: TX has several modes:
--   row lock contention     = uncommitted row
--   allocate ITL entry      = INITRANS / ITL shortage
--   index contention        = index block split / unique key
-- Difference vs 04: 04 is row lock only; this file includes ITL and index TX.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: All TX enqueue waits
--------------------------------------------------------------------------------
-- 1. What the query does
--    EVENT LIKE enq: TX%.
-- 2. Important columns
--    EVENT, SID, BLOCKER, SQL_ID.
-- 3. How to interpret the output
--    allocate ITL entry → consider INITRANS/ASSM (often not the first knob). index contention → hot unique index.
-- 4. What indicates a problem
--    ITL waits on a table after a massive parallel insert.
-- 5. Recommended DBA action
--    Different fix than row locks — do not kill the blocker first; check the exact event text.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$LOCK
--------------------------------------------------------------------------------
SELECT inst_id, sid, serial#, username, event, seconds_in_wait,
       blocking_session, blocking_instance, sql_id, module
FROM   gv$session
WHERE  event LIKE 'enq: TX%'
ORDER BY event, seconds_in_wait DESC;

SELECT inst_id, sid, type, lmode, request, id1, id2, block, ctime
FROM   gv$lock
WHERE  type = 'TX'
ORDER BY block DESC, ctime DESC;

PROMPT
PROMPT === End of query: All TX enqueue waits ===
PROMPT

-- End of file
