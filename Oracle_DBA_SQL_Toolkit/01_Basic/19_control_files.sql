--------------------------------------------------------------------------------
-- File Name       : 19_control_files.sql
-- Category        : 01_Basic
-- Purpose         : List control file multiplexed copies and status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Production databases must multiplex control files on independent
-- failure groups or disks. A single control file is a single point of failure.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Control file locations and status
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$CONTROLFILE for name, status, and is_recovery_dest_file.
-- 2. Important columns
--    NAME, STATUS, IS_RECOVERY_DEST_FILE, BLOCK_SIZE, FILE_SIZE_BLKS.
-- 3. How to interpret the output
--    STATUS NULL is healthy. STATUS INVALID means that copy is unusable.
-- 4. What indicates a problem
--    Only one control file. A copy on the same ASM diskgroup as the only other copy with NORMAL redundancy still shares some risk if the diskgroup is lost.
-- 5. Recommended DBA action
--    Add a multiplexed copy on a separate diskgroup. Do not move control files without a change window and backup.
-- 6. Production cautions
--    Safe. Do not ALTER DATABASE BACKUP CONTROLFILE or RENAME here.
-- 7. Required privileges
--    SELECT on V_$CONTROLFILE, V_$PARAMETER
--------------------------------------------------------------------------------
SELECT
       status,
       name,
       is_recovery_dest_file,
       block_size,
       file_size_blks
FROM   v$controlfile
ORDER BY name;

SELECT name, value
FROM   v$parameter
WHERE  name = 'control_files';

PROMPT
PROMPT === End of query: Control file locations and status ===
PROMPT

-- End of file
