--------------------------------------------------------------------------------
-- File Name       : 08_gc_cr_requests.sql
-- Category        : 15_RAC
-- Purpose         : GC CR (consistent read) traffic
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: reading a consistent version from another instance. Cause: read/write split across nodes on same blocks.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: CR events and cache fusion stats
--------------------------------------------------------------------------------
-- 1. What the query does
--    gc cr% events + V$SYSSTAT gc cr.
-- 2. Important columns
--    EVENT, BLOCKS.
-- 3. How to interpret the output
--    High CR is common; high flush + CR may mean write-read ping.
-- 4. What indicates a problem
--    CR avg_ms high (interconnect latency).
-- 5. Recommended DBA action
--    15/12 interconnect.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$system_event WHERE event LIKE 'gc cr%'
ORDER BY time_s DESC;
SELECT inst_id, name, value FROM gv$sysstat WHERE name LIKE 'gc cr%' ORDER BY inst_id, name;

PROMPT
PROMPT === End of query: CR events and cache fusion stats ===
PROMPT

-- End of file
