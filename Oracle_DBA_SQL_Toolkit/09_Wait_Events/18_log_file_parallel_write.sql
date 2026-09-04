--------------------------------------------------------------------------------
-- File Name       : 18_log_file_parallel_write.sql
-- Category        : 09_Wait_Events
-- Purpose         : log file parallel write (LGWR I/O)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: LGWR writing redo members.
-- Possible Cause: slow/uneven multiplexed members, remote sync dest, overloaded ASM.
-- How to Investigate: V$LOGFILE members on different devices; ASM latency (16_ASM).
-- Possible Fix: put members on fast isolated disks; fix the slow copy (one bad member slows all).
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
-- QUERY 1: LGWR write event and redo members
--------------------------------------------------------------------------------
-- 1. What the query does
--    Event + V$LOGFILE locations.
-- 2. Important columns
--    AVG_MS, MEMBER path.
-- 3. How to interpret the output
--    One member on NFS and one on ASM flash will run at NFS speed.
-- 4. What indicates a problem
--    avg_ms jumped after adding a multiplex member on slow storage.
-- 5. Recommended DBA action
--    Relocate the slow member in a window.
-- 6. Production cautions
--    Safe to query. Dropping a logfile member is a change.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, V_$LOGFILE, V_$LOG
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event = 'log file parallel write';

SELECT group#, status, type, member FROM v$logfile ORDER BY group#;

PROMPT
PROMPT === End of query: LGWR write event and redo members ===
PROMPT

-- End of file
