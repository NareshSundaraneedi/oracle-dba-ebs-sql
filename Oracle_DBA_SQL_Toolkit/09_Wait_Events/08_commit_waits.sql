--------------------------------------------------------------------------------
-- File Name       : 08_commit_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Commit-related waits (log file sync primarily)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: after COMMIT the session waits for redo to be durable.
-- Cause: LGWR slow, too many commits, poor redo I/O, adaptive log file sync.
-- Investigate: 17_log_file_sync + 12_Redo.
-- Fix: fewer commits, faster redo disks, fix LGWR issues — not larger SGA.
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
-- QUERY 1: Commit class events
--------------------------------------------------------------------------------
-- 1. What the query does
--    WAIT_CLASS = Commit.
-- 2. Important columns
--    EVENT, AVG_MS.
-- 3. How to interpret the output
--    log file sync avg > 5-10ms is usually storage or commit storm.
-- 4. What indicates a problem
--    Commit class dominates DB time.
-- 5. Recommended DBA action
--    17 and redo generation rate.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'Commit'
OR     event IN ('log file sync','log file parallel write')
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: Commit class events ===
PROMPT

-- End of file
