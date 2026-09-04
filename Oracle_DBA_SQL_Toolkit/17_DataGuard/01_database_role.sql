--------------------------------------------------------------------------------
-- File Name       : 01_database_role.sql
-- Category        : 17_DataGuard
-- Purpose         : Confirm DATABASE_ROLE on this member
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Never perform primary-only actions on a standby.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Role
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATABASE role columns.
-- 2. Important columns
--    DATABASE_ROLE, OPEN_MODE, SWITCHOVER_STATUS.
-- 3. How to interpret the output
--    PRIMARY vs PHYSICAL STANDBY vs SNAPSHOT STANDBY.
-- 4. What indicates a problem
--    Role not what the runbook says.
-- 5. Recommended DBA action
--    Stop. Verify broker. Do not open READ WRITE on a physical standby.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$DATABASE
--------------------------------------------------------------------------------
SELECT name, db_unique_name, database_role, open_mode, protection_mode, switchover_status, dataguard_broker
FROM v$database;

PROMPT
PROMPT === End of query: Role ===
PROMPT

-- End of file
