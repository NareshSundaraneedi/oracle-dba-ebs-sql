--------------------------------------------------------------------------------
-- File Name       : 09_spfile_backup.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : SPFILE included in autobackup
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SPFILE is backed up with controlfile autobackup. Confirm autobackup and that an SPFILE is in use.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SPFILE and autobackup
--------------------------------------------------------------------------------
-- 1. What the query does
--    SPFILE parameter + autobackup config.
-- 2. Important columns
--    SPFILE path, AUTOBACKUP.
-- 3. How to interpret the output
--    Started from PFILE means restore of SPFILE is a different path.
-- 4. What indicates a problem
--    No SPFILE and AUTOBACKUP OFF.
-- 5. Recommended DBA action
--    Create SPFILE and enable autobackup in a window.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$RMAN_CONFIGURATION
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter WHERE name = 'spfile';
SELECT name, value FROM v$rman_configuration WHERE name LIKE '%AUTOBACKUP%';

PROMPT
PROMPT === End of query: SPFILE and autobackup ===
PROMPT

-- End of file
