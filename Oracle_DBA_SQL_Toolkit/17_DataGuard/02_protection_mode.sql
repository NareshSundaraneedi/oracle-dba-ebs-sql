--------------------------------------------------------------------------------
-- File Name       : 02_protection_mode.sql
-- Category        : 17_DataGuard
-- Purpose         : Maximum Performance / Availability / Protection
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SYNC + Maximum Protection can stall the primary if the standby is down.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Protection mode and level
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATABASE + dests.
-- 2. Important columns
--    PROTECTION_MODE, PROTECTION_LEVEL.
-- 3. How to interpret the output
--    LEVEL can be lower than MODE when a dest is down.
-- 4. What indicates a problem
--    MODE MAXIMUM PROTECTION and LEVEL lower — primary at risk of shutdown.
-- 5. Recommended DBA action
--    Fix the dest or change mode in a planned way (broker).
-- 6. Production cautions
--    Safe. ALTER DATABASE SET STANDBY not executed.
-- 7. Required privileges
--    SELECT on V_$DATABASE
--------------------------------------------------------------------------------
SELECT protection_mode, protection_level, database_role FROM v$database;

PROMPT
PROMPT === End of query: Protection mode and level ===
PROMPT

-- End of file
