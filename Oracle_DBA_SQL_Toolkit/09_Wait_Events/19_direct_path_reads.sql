--------------------------------------------------------------------------------
-- File Name       : 19_direct_path_reads.sql
-- Category        : 09_Wait_Events
-- Purpose         : direct path read / direct path read temp
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: reads that bypass the buffer cache (serial FTS on large
-- tables, PX, temp reads).
-- Possible Cause: large FTS, hash join spill, parallel query.
-- How to Investigate: event name temp vs not. SQL_ID. PGA/TEMP usage.
-- Possible Fix: tune the SQL; increase PGA if spilling; do not disable direct path globally.
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
-- QUERY 1: Direct path read events and waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    System events + current waiters.
-- 2. Important columns
--    EVENT, SQL_ID.
-- 3. How to interpret the output
--    direct path read temp = TEMP I/O (spill). direct path read = table/index FTS bypassing cache.
-- 4. What indicates a problem
--    read temp high — hash/sort spill (14_TEMP).
-- 5. Recommended DBA action
--    PGA workarea + SQL tune.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SESSION
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event LIKE 'direct path read%';

SELECT inst_id, sid, username, event, sql_id, module, seconds_in_wait
FROM   gv$session
WHERE  event LIKE 'direct path read%';

PROMPT
PROMPT === End of query: Direct path read events and waiters ===
PROMPT

-- End of file
