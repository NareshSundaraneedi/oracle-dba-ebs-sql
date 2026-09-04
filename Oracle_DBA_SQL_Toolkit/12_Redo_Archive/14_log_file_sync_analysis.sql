--------------------------------------------------------------------------------
-- File Name       : 14_log_file_sync_analysis.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Redo-folder companion to 09/17 log file sync
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 09/17: adds commit rate and redo size together so the redo DBA can act without leaving the folder.
--
-- See 09_Wait_Events/17 for Meaning/Cause/Fix narrative.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Sync, write, commits, redo size
--------------------------------------------------------------------------------
-- 1. What the query does
--    Combines events and sysstat.
-- 2. Important columns
--    AVG_MS, USER_COMMITS, REDO_SIZE.
-- 3. How to interpret the output
--    High commits + high sync = chatty transactions (EBS forms save).
-- 4. What indicates a problem
--    Same as 09/17 problem set.
-- 5. Recommended DBA action
--    Application batching. Redo disk. DG SYNC dest.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT inst_id, event, ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM gv$system_event WHERE event IN ('log file sync','log file parallel write');
SELECT inst_id, name, value FROM gv$sysstat
WHERE name IN ('user commits','redo size','redo synch writes');

PROMPT
PROMPT === End of query: Sync, write, commits, redo size ===
PROMPT

-- End of file
