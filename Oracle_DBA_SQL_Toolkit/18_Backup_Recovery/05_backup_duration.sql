--------------------------------------------------------------------------------
-- File Name       : 05_backup_duration.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Backup runtime trend
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Durations growing toward the backup window limit.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Duration by day
--------------------------------------------------------------------------------
-- 1. What the query does
--    Jobs with elapsed seconds.
-- 2. Important columns
--    START_TIME, ELAPSED_SECONDS, OUTPUT_GB.
-- 3. How to interpret the output
--    Runtime growing with database size is expected; sudden 3x is not.
-- 4. What indicates a problem
--    Backup still RUNNING into production peak.
-- 5. Recommended DBA action
--    Tune channels/section size or move window. Do not kill RMAN mid-backup casually.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$RMAN_BACKUP_JOB_DETAILS
--------------------------------------------------------------------------------
SELECT start_time, input_type, status, elapsed_seconds,
       ROUND(output_bytes/1024/1024/1024,2) output_gb
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-14
ORDER BY start_time;

PROMPT
PROMPT === End of query: Duration by day ===
PROMPT

-- End of file
