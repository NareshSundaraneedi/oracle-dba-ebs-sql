--------------------------------------------------------------------------------
-- File Name       : 11_rman_validation.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : How to validate backups (commands only)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- RESTORE VALIDATE and BACKUP VALIDATE read backup pieces without restoring. They are I/O heavy — run in a window. Not auto-executed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Validation guidance
--------------------------------------------------------------------------------
-- 1. What the query does
--    Prints RMAN validate examples as comments and lists pieces to validate.
-- 2. Important columns
--    HANDLE, STATUS.
-- 3. How to interpret the output
--    VALIDATE checks readability, not that you practiced a restore.
-- 4. What indicates a problem
--    Pieces STATUS AVAILABLE but never validated after tape library errors.
-- 5. Recommended DBA action
--    WARNING: RMAN VALIDATE is I/O heavy. Run manually.
-- 6. Production cautions
--    WARNING: Not executed.
-- 7. Required privileges
--    SELECT on V_$BACKUP_PIECE
--------------------------------------------------------------------------------
SELECT handle, status, start_time, ROUND(bytes/1024/1024/1024,2) gb
FROM v$backup_piece
WHERE status = 'AVAILABLE'
AND start_time > SYSDATE-7
ORDER BY start_time DESC;
PROMPT RMAN (manual, change window):
PROMPT   RESTORE DATABASE VALIDATE;
PROMPT   RESTORE ARCHIVELOG FROM TIME 'SYSDATE-1' VALIDATE;
PROMPT   BACKUP VALIDATE DATABASE;

PROMPT
PROMPT === End of query: Validation guidance ===
PROMPT

-- End of file
