--------------------------------------------------------------------------------
-- File Name       : 21_archive_log_mode.sql
-- Category        : 01_Basic
-- Purpose         : Confirm ARCHIVELOG mode and current archive destinations
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Production and any database that requires point-in-time recovery
-- must run in ARCHIVELOG mode. This script confirms mode and dest status.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Log mode and archive destinations
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$DATABASE.LOG_MODE and V$ARCHIVE_DEST_STATUS.
-- 2. Important columns
--    LOG_MODE, DEST_ID, DESTINATION, STATUS, ERROR, TYPE.
-- 3. How to interpret the output
--    ARCHIVELOG is required for RMAN online backups and Data Guard. Dest STATUS ERROR needs immediate attention.
-- 4. What indicates a problem
--    NOARCHIVELOG on production. Dest VALID but ERROR populated. Local dest FULL.
-- 5. Recommended DBA action
--    If dest is full, free space or add dest. Enabling ARCHIVELOG requires a bounce in MOUNT — change window only.
-- 6. Production cautions
--    Safe. Do not ALTER DATABASE ARCHIVELOG from this script.
-- 7. Required privileges
--    SELECT on V_$DATABASE, V_$ARCHIVE_DEST_STATUS
--------------------------------------------------------------------------------
SELECT name, log_mode, force_logging FROM v$database;

SELECT
       dest_id,
       dest_name,
       status,
       type,
       database_mode,
       recovery_mode,
       destination,
       error,
       gap_status
FROM   v$archive_dest_status
WHERE  status <> 'INACTIVE'
ORDER BY dest_id;

PROMPT
PROMPT === End of query: Log mode and archive destinations ===
PROMPT

-- End of file
