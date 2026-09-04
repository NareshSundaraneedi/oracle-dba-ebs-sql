--------------------------------------------------------------------------------
-- File Name       : 03_backup_status.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Latest backup per type
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- When was the last successful full, incremental, archivelog backup?
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Last success by input_type
--------------------------------------------------------------------------------
-- 1. What the query does
--    Max completed time.
-- 2. Important columns
--    INPUT_TYPE, LAST_SUCCESS.
-- 3. How to interpret the output
--    Archivelog backups should be frequent (hours).
-- 4. What indicates a problem
--    Last full older than retention / policy.
-- 5. Recommended DBA action
--    Run the missing backup in the approved window.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$RMAN_BACKUP_JOB_DETAILS
--------------------------------------------------------------------------------
SELECT input_type,
       MAX(CASE WHEN status LIKE 'COMPLETED%' THEN end_time END) last_success,
       MAX(end_time) last_any
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-30
GROUP BY input_type
ORDER BY input_type;

PROMPT
PROMPT === End of query: Last success by input_type ===
PROMPT

-- End of file
