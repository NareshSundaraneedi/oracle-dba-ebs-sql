--------------------------------------------------------------------------------
-- File Name       : 04_failed_backups.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Failed / incomplete RMAN jobs
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- STATUS FAILED or RUNNING far too long.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Failed jobs
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filter status.
-- 2. Important columns
--    STATUS, START_TIME, TIME_TAKEN.
-- 3. How to interpret the output
--    A failed archivelog backup plus FRA pressure is an outage waiting to happen.
-- 4. What indicates a problem
--    FAILED last night.
-- 5. Recommended DBA action
--    RMAN log + dest space + tape/library.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$RMAN_BACKUP_JOB_DETAILS
--------------------------------------------------------------------------------
SELECT session_key, input_type, status, start_time, end_time, time_taken_display
FROM v$rman_backup_job_details
WHERE status NOT LIKE 'COMPLETED%'
AND start_time > SYSDATE-14
ORDER BY start_time DESC;

PROMPT
PROMPT === End of query: Failed jobs ===
PROMPT

-- End of file
