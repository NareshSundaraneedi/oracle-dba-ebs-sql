--------------------------------------------------------------------------------
-- File Name       : 16_db_file_scattered_read.sql
-- Category        : 09_Wait_Events
-- Purpose         : db file scattered read (multiblock FTS/index fast full)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: multiblock read for FTS or index fast full scan.
-- Possible Cause: missing/unusable index, bad plan, implicit conversion, reporting during OLTP.
-- How to Investigate: current waiters' SQL_ID → plan. Compare to 07/24.
-- Possible Fix: fix the plan. Increase db_file_multiblock_read_count is rarely the right prod fix.
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
-- QUERY 1: Scattered read and waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    Event stats + active waiters.
-- 2. Important columns
--    AVG_MS, SQL_ID.
-- 3. How to interpret the output
--    High waits during business hours on an OLTP module = likely bad plan.
-- 4. What indicates a problem
--    A new scattered-read SQL after stats gather.
-- 5. Recommended DBA action
--    DISPLAY_CURSOR and 07/14 regressions.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SESSION
--------------------------------------------------------------------------------
SELECT inst_id, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event = 'db file scattered read';

SELECT inst_id, sid, username, sql_id, module, seconds_in_wait, p1, p2, p3
FROM   gv$session
WHERE  event = 'db file scattered read'
AND    status = 'ACTIVE';

PROMPT
PROMPT === End of query: Scattered read and waiters ===
PROMPT

-- End of file
