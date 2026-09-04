--------------------------------------------------------------------------------
-- File Name       : 05_io_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : All User I/O and System I/O wait events
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: I/O wait class is time spent in storage calls.
-- Cause: slow disks, huge FTS, checkpoint writes, temp spills.
-- Investigate: avg wait ms, ASH by event, SQL with disk_reads.
-- Fix: tune SQL, add IOPs, separate redo/data — not 'increase SGA' as the first step.
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
-- QUERY 1: I/O wait classes
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters WAIT_CLASS IN (User I/O, System I/O).
-- 2. Important columns
--    EVENT, TIME_WAITED_S, AVG_MS.
-- 3. How to interpret the output
--    User I/O is foreground. System I/O is DBWR/LGWR/ARCn.
-- 4. What indicates a problem
--    User I/O avg > 10-20ms on SAN claimed to be flash.
-- 5. Recommended DBA action
--    Storage team + top physical SQL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, wait_class, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class IN ('User I/O','System I/O')
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: I/O wait classes ===
PROMPT

-- End of file
