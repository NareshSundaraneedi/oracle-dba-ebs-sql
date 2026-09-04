--------------------------------------------------------------------------------
-- File Name       : 08_controlfile_backup.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Control file autobackup and recent copies
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Controlfile autobackup ON is mandatory on production. V$CONTROLFILE_COPY lists copies.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Controlfile backups
--------------------------------------------------------------------------------
-- 1. What the query does
--    RMAN config + V$CONTROLFILE_RECORD_SECTION / copies.
-- 2. Important columns
--    AUTOBACKUP, CONTROLFILE COPIES.
-- 3. How to interpret the output
--    Autobackup pieces live with the backup destination / FRA.
-- 4. What indicates a problem
--    AUTOBACKUP OFF or no recent controlfile backup.
-- 5. Recommended DBA action
--    RMAN: CONFIGURE CONTROLFILE AUTOBACKUP ON; BACKUP CURRENT CONTROLFILE;
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$RMAN_CONFIGURATION, V_$CONTROLFILE_COPY
--------------------------------------------------------------------------------
SELECT name, value FROM v$rman_configuration WHERE name LIKE '%CONTROLFILE%';
SELECT stamp, name, status, completion_time FROM v$controlfile_copy ORDER BY completion_time DESC FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: Controlfile backups ===
PROMPT

-- End of file
