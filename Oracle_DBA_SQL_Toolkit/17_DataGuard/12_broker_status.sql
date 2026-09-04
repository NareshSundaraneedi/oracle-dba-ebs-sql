--------------------------------------------------------------------------------
-- File Name       : 12_broker_status.sql
-- Category        : 17_DataGuard
-- Purpose         : Data Guard broker configuration (SQL + DGMGRL hints)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$DG_BROKER_CONFIG / V$DATAGUARD_CONFIG. DGMGRL SHOW CONFIGURATION is authoritative for enabledness.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Broker views
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATAGUARD_CONFIG and parameter DG_BROKER_START.
-- 2. Important columns
--    DB_UNIQUE_NAME, PARENT.
-- 3. How to interpret the output
--    DG_BROKER_START FALSE means broker is off (SQL-only manage).
-- 4. What indicates a problem
--    Broker enabled but configuration ERROR (check DGMGRL).
-- 5. Recommended DBA action
--    DGMGRL: SHOW CONFIGURATION; SHOW DATABASE verbose;
-- 6. Production cautions
--    Safe. DGMGRL not executed from SQL*Plus here.
-- 7. Required privileges
--    SELECT on V_$DATAGUARD_CONFIG, V_$PARAMETER
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter WHERE name IN ('dg_broker_start','dg_broker_config_file1','dg_broker_config_file2');
SELECT * FROM v$dataguard_config;
PROMPT DGMGRL (run from OS):
PROMPT   SHOW CONFIGURATION;
PROMPT   SHOW DATABASE verbose '<db_unique_name>';

PROMPT
PROMPT === End of query: Broker views ===
PROMPT

-- End of file
