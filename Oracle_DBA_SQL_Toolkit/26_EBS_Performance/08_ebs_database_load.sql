--------------------------------------------------------------------------------
-- File Name       : 08_ebs_database_load.sql
-- Category        : 26_EBS_Performance
-- Purpose         : EBS-oriented load snapshot (APPS sessions + time model)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- One-page load for an EBS DBA shift start.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Load snapshot
--------------------------------------------------------------------------------
-- 1. What the query does
--    APPS session counts + DB time.
-- 2. Important columns
--    APPS_ACTIVE, DB_TIME, DB_CPU.
-- 3. How to interpret the output
--    APPS_ACTIVE >> CPU_COUNT and wait_class not Idle = overload.
-- 4. What indicates a problem
--    APPS_ACTIVE spike with login storm.
-- 5. Recommended DBA action
--    06_Sessions / 30 connection.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT COUNT(*) apps_sessions, SUM(DECODE(status,'ACTIVE',1,0)) apps_active
FROM gv$session WHERE username='APPS';
SELECT stat_name, ROUND(value/1e6,1) seconds FROM v$sys_time_model
WHERE stat_name IN ('DB time','DB CPU');

PROMPT
PROMPT === End of query: Load snapshot ===
PROMPT

-- End of file
