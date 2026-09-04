--------------------------------------------------------------------------------
-- File Name       : 13_restore_validation.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : RESTORE PREVIEW / VALIDATE workflow (manual)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- RESTORE DATABASE PREVIEW summarizes which backups RMAN would use. Read-only and useful before a real restore. I/O light vs VALIDATE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Preview guidance
--------------------------------------------------------------------------------
-- 1. What the query does
--    Documents PREVIEW. Lists latest backup set keys.
-- 2. Important columns
--    SESSION_KEY, INPUT_TYPE.
-- 3. How to interpret the output
--    PREVIEW shows the recovery plan without doing it.
-- 4. What indicates a problem
--    PREVIEW reports a gap — recoverability broken.
-- 5. Recommended DBA action
--    Restore missing backups/archivelogs. Do not run RESTORE DATABASE without a declared incident.
-- 6. Production cautions
--    WARNING: RESTORE without PREVIEW/VALIDATE in prod is dangerous. Not executed.
-- 7. Required privileges
--    SELECT on V_$RMAN_BACKUP_JOB_DETAILS
--------------------------------------------------------------------------------
SELECT session_key, input_type, status, start_time, output_device_type
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-14
ORDER BY start_time DESC;
PROMPT RMAN (manual):
PROMPT   RESTORE DATABASE PREVIEW;
PROMPT   RESTORE DATABASE PREVIEW SUMMARY;

PROMPT
PROMPT === End of query: Preview guidance ===
PROMPT

-- End of file
