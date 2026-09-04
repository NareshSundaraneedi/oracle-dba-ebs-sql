--------------------------------------------------------------------------------
-- File Name       : 02_rman_backups.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Recent RMAN backup jobs
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$RMAN_BACKUP_JOB_DETAILS is the job-level view (11g+).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Backup jobs 14 days
--------------------------------------------------------------------------------
-- 1. What the query does
--    Job details.
-- 2. Important columns
--    START_TIME, STATUS, INPUT_TYPE, OUTPUT_BYTES.
-- 3. How to interpret the output
--    COMPLETED is healthy. COMPLETED WITH WARNINGS still needs a look.
-- 4. What indicates a problem
--    No successful FULL/DB INCR in the retention window.
-- 5. Recommended DBA action
--    Open RMAN logs. Do not delete backups to 'make space' without a restore test plan.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$RMAN_BACKUP_JOB_DETAILS
--------------------------------------------------------------------------------
SELECT session_key, input_type, status,
       TO_CHAR(start_time,'DD-MON-RR HH24:MI') start_time,
       TO_CHAR(end_time,'DD-MON-RR HH24:MI') end_time,
       ROUND(input_bytes/1024/1024/1024,2) input_gb,
       ROUND(output_bytes/1024/1024/1024,2) output_gb,
       time_taken_display
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-14
ORDER BY start_time DESC;

PROMPT
PROMPT === End of query: Backup jobs 14 days ===
PROMPT

-- End of file
