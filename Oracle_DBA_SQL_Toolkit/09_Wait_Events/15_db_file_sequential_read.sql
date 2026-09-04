--------------------------------------------------------------------------------
-- File Name       : 15_db_file_sequential_read.sql
-- Category        : 09_Wait_Events
-- Purpose         : db file sequential read (single-block reads)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: single-block read, typically index lookup or table by ROWID.
-- Possible Cause: lots of index access (normal OLTP), slow storage, poor clustering (many ROWID jumps), missing join efficiency.
-- How to Investigate: avg_ms (latency) vs total_waits (volume). ASH SQL_ID. clustering factor.
-- Possible Fix: if latency — storage. if volume — better index/join/SQL. Not 'add indexes' blindly.
--
-- Pack-free.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Sequential read latency and current waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    System event + sessions waiting on it.
-- 2. Important columns
--    AVG_MS, SID, SQL_ID, P1 file P2 block.
-- 3. How to interpret the output
--    avg 1ms flash, 5-15ms spinning SAN, >20ms problem.
-- 4. What indicates a problem
--    avg_ms jumped but wait count did not — storage regression.
-- 5. Recommended DBA action
--    Confirm with storage metrics. Get SQL_ID from waiters.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SESSION
--------------------------------------------------------------------------------
SELECT inst_id, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event = 'db file sequential read';

SELECT inst_id, sid, username, sql_id, module, p1 file#, p2 block#, seconds_in_wait
FROM   gv$session
WHERE  event = 'db file sequential read'
AND    status = 'ACTIVE';

PROMPT
PROMPT === End of query: Sequential read latency and current waiters ===
PROMPT

-- End of file
