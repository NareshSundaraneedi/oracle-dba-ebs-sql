--------------------------------------------------------------------------------
-- File Name       : 01_rman_configuration.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : RMAN persistent configuration (from the DB)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$RMAN_CONFIGURATION shows CONFIGURE settings stored in the control file.
--
-- RMAN views require the database to be using RMAN (normal).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: RMAN config
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$RMAN_CONFIGURATION.
-- 2. Important columns
--    NAME, VALUE.
-- 3. How to interpret the output
--    CONTROLFILE AUTOBACKUP should be ON. RETENTION POLICY must match FRA/backups.
-- 4. What indicates a problem
--    AUTOBACKUP OFF on production.
-- 5. Recommended DBA action
--    Change via RMAN CONFIGURE — not SQL. Shown as prompt.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$RMAN_CONFIGURATION
--------------------------------------------------------------------------------
SELECT name, value FROM v$rman_configuration ORDER BY name;
PROMPT Review in RMAN: SHOW ALL;

PROMPT
PROMPT === End of query: RMAN config ===
PROMPT

-- End of file
