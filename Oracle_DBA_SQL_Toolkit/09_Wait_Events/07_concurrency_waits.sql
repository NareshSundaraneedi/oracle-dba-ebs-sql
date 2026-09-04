--------------------------------------------------------------------------------
-- File Name       : 07_concurrency_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Concurrency wait class (latches, buffers, mutexes)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: waits for shared memory structures.
-- Cause: hot blocks, sequence, library cache mutex, undo header.
-- Investigate: event name → specific script (14 buffer busy, 13 library cache).
-- Fix: reduce contention (reverse index, hash partition, fix parse) — not more CPUs first.
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
-- QUERY 1: Concurrency events
--------------------------------------------------------------------------------
-- 1. What the query does
--    WAIT_CLASS = Concurrency.
-- 2. Important columns
--    EVENT, TIME_S.
-- 3. How to interpret the output
--    latch: cache buffers chains and buffer busy waits often travel together (hot block).
-- 4. What indicates a problem
--    Concurrency #1 on a previously quiet system after a code deploy.
-- 5. Recommended DBA action
--    Identify the hot object (ASH p1/p2 or V$SEGMENT_STATISTICS).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'Concurrency'
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: Concurrency events ===
PROMPT

-- End of file
