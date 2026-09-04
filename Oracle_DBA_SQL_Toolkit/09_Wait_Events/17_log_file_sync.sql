--------------------------------------------------------------------------------
-- File Name       : 17_log_file_sync.sql
-- Category        : 09_Wait_Events
-- Purpose         : log file sync deep dive
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: session COMMIT waiting for LGWR to finish.
-- Possible Cause: (1) commit storm (2) slow redo I/O (3) LGWR CPU starve (4) Data Guard sync dest.
-- How to Investigate: compare log file sync vs log file parallel write avg. If both high → storage/standby. If sync high and parallel write low → scheduling/commit rate.
-- Possible Fix: batch commits, faster redo, NODELAY/async review for DG, isolate LGWR.
--
-- Pack-free. See also 12_Redo_Archive/14.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Sync vs parallel write
--------------------------------------------------------------------------------
-- 1. What the query does
--    Compares the two LGWR-related events and commit rate.
-- 2. Important columns
--    SYNC_AVG_MS, PARALLEL_WRITE_AVG_MS, USER_COMMITS.
-- 3. How to interpret the output
--    parallel write ≈ storage time. sync - parallel write ≈ extra (CPU, posting).
-- 4. What indicates a problem
--    sync 20ms, parallel write 2ms — not the disks; look at CPU/posting/commit rate.
-- 5. Recommended DBA action
--    12_Redo generation + application commit frequency.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms,
       ROUND(time_waited_micro/1e6,1) time_s
FROM   gv$system_event
WHERE  event IN ('log file sync','log file parallel write','log file switch completion','log file switch (checkpoint incomplete)');

SELECT inst_id, name, value
FROM   gv$sysstat
WHERE  name IN ('user commits','user rollbacks','redo size','redo synch writes','redo synch time');

PROMPT
PROMPT === End of query: Sync vs parallel write ===
PROMPT

-- End of file
