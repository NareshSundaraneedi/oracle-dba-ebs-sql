--------------------------------------------------------------------------------
-- File Name       : 07_archive_backup.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Archivelog backup coverage
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Are there sequences since yesterday without a backup (needed for PITR)?
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Archived vs backed up
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$ARCHIVED_LOG.BACKUP_COUNT / V$BACKUP_REDOLOG.
-- 2. Important columns
--    SEQUENCE#, BACKUP_COUNT, DELETED.
-- 3. How to interpret the output
--    BACKUP_COUNT 0 and DELETED YES = unrecoverable gap.
-- 4. What indicates a problem
--    Unbacked archives deleted by FRA/RMAN policy.
-- 5. Recommended DBA action
--    RMAN BACKUP ARCHIVELOG. Stop FRA auto-delete until backups succeed.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVED_LOG
--------------------------------------------------------------------------------
SELECT thread#, sequence#, first_time, backup_count, deleted, name
FROM v$archived_log
WHERE first_time > SYSDATE-2
AND dest_id = 1
AND NVL(backup_count,0) = 0
ORDER BY thread#, sequence#;

PROMPT
PROMPT === End of query: Archived vs backed up ===
PROMPT

-- End of file
