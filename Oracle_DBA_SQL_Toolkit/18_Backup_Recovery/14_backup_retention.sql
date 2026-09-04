--------------------------------------------------------------------------------
-- File Name       : 14_backup_retention.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Retention policy vs FRA and obsolete backups
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- REDUNDANCY vs RECOVERY WINDOW. Obsolete backups can fill FRA if DELETE OBSOLETE is not run.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Retention config and FRA reclaimable
--------------------------------------------------------------------------------
-- 1. What the query does
--    RMAN config + FRA usage.
-- 2. Important columns
--    RETENTION, PERCENT_SPACE_RECLAIMABLE.
-- 3. How to interpret the output
--    High reclaimable + full FRA means DELETE OBSOLETE / backup archivelog delete input is overdue.
-- 4. What indicates a problem
--    FRA critical and reclaimable high.
-- 5. Recommended DBA action
--    RMAN DELETE OBSOLETE is destructive to old backups — run only if policy allows. Generated as prompt.
-- 6. Production cautions
--    WARNING: DELETE OBSOLETE is destructive. Not executed.
-- 7. Required privileges
--    SELECT on V_$RMAN_CONFIGURATION, V_$RECOVERY_AREA_USAGE
--------------------------------------------------------------------------------
SELECT name, value FROM v$rman_configuration WHERE name LIKE '%RETENTION%' OR name LIKE '%ARCHIVELOG%';
SELECT file_type, percent_space_used, percent_space_reclaimable, number_of_files
FROM v$recovery_area_usage;
PROMPT RMAN (manual, after confirming policy):
PROMPT   REPORT OBSOLETE;
PROMPT   DELETE NOPROMPT OBSOLETE;  -- WARNING destructive

PROMPT
PROMPT === End of query: Retention config and FRA reclaimable ===
PROMPT

-- End of file
