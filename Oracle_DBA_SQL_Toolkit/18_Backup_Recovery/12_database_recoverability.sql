--------------------------------------------------------------------------------
-- File Name       : 12_database_recoverability.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Recoverability to a point in time (V$RECOVER_FILE / backup redologs)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$RECOVER_FILE rows mean a datafile needs recovery now (incident). For backup recoverability, check archivelog continuity + backup age.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Current recover files and backup age
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$RECOVER_FILE plus last backup.
-- 2. Important columns
--    FILE#, ERROR, LAST_BACKUP.
-- 3. How to interpret the output
--    Any V$RECOVER_FILE row on an OPEN DB is a media recovery incident.
-- 4. What indicates a problem
--    Files in recover + no recent backup.
-- 5. Recommended DBA action
--    RMAN RESTORE/RECOVER — incident command, not here.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on V_$RECOVER_FILE, V_$RMAN_BACKUP_JOB_DETAILS, V_$DATAFILE
--------------------------------------------------------------------------------
SELECT * FROM v$recover_file;
SELECT file#, name, status FROM v$datafile WHERE status NOT IN ('SYSTEM','ONLINE');
SELECT MAX(end_time) last_completed_backup
FROM v$rman_backup_job_details
WHERE status LIKE 'COMPLETED%' AND input_type IN ('DB FULL','DB INCR','DATAFILE FULL','DATAFILE INCR');

PROMPT
PROMPT === End of query: Current recover files and backup age ===
PROMPT

-- End of file
