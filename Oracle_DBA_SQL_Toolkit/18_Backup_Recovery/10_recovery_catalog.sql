--------------------------------------------------------------------------------
-- File Name       : 10_recovery_catalog.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Is a recovery catalog in use (from the target)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- The target does not always show catalog use. RC_* views exist only when connected to the catalog DB. This checks V$RMAN_STATUS comments and prompts.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Catalog hints
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$RMAN_BACKUP_JOB_DETAILS session info + prompt.
-- 2. Important columns
--    SESSION_RECID.
-- 3. How to interpret the output
--    If you have a catalog, run RC views there (RC_DATABASE, RC_BACKUP_SET).
-- 4. What indicates a problem
--    Catalog DB down — backups may still succeed to control file but reports suffer.
-- 5. Recommended DBA action
--    Connect RMAN to catalog and RESYNC.
-- 6. Production cautions
--    Safe. No catalog writes.
-- 7. Required privileges
--    SELECT on V_$RMAN_BACKUP_JOB_DETAILS
--------------------------------------------------------------------------------
SELECT session_key, start_time, input_type, status
FROM v$rman_backup_job_details WHERE start_time > SYSDATE-3 ORDER BY start_time DESC;
PROMPT On the catalog database (if used):
PROMPT   SELECT dbid, name, resetlogs_time FROM rc_database;
PROMPT   SELECT status, COUNT(*) FROM rc_backup_set GROUP BY status;

PROMPT
PROMPT === End of query: Catalog hints ===
PROMPT

-- End of file
