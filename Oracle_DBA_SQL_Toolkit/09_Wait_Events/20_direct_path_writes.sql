--------------------------------------------------------------------------------
-- File Name       : 20_direct_path_writes.sql
-- Category        : 09_Wait_Events
-- Purpose         : direct path write / write temp
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: writes bypassing buffer cache (CTAS, insert append, temp).
-- Possible Cause: load jobs, temp spills, PDML.
-- How to Investigate: waiters' SQL. TEMP usage.
-- Possible Fix: tune or reschedule loads; check TEMP sizing.
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
-- QUERY 1: Direct path write events
--------------------------------------------------------------------------------
-- 1. What the query does
--    System events + waiters.
-- 2. Important columns
--    EVENT, SQL_ID.
-- 3. How to interpret the output
--    write temp with huge TEMP usage = spill.
-- 4. What indicates a problem
--    Direct writes saturating storage during an index rebuild.
-- 5. Recommended DBA action
--    Reschedule rebuilds. See 14_TEMP.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SESSION
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event LIKE 'direct path write%';

SELECT inst_id, sid, username, event, sql_id, module, seconds_in_wait
FROM   gv$session
WHERE  event LIKE 'direct path write%';

PROMPT
PROMPT === End of query: Direct path write events ===
PROMPT

-- End of file
