--------------------------------------------------------------------------------
-- File Name       : 09_standby_status.sql
-- Category        : 17_DataGuard
-- Purpose         : Standby database view (role, recover, FSFO)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Run on standby. Combines role, open mode, MRP, lag.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Standby snapshot
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATABASE + stats + MRP.
-- 2. Important columns
--    ROLE, OPEN_MODE, LAG, MRP STATUS.
-- 3. How to interpret the output
--    ADG: OPEN READ ONLY + MRP running.
-- 4. What indicates a problem
--    SNAPSHOT STANDBY when you needed physical.
-- 5. Recommended DBA action
--    CONVERT TO PHYSICAL via broker after snapshot work.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$DATABASE, V_$DATAGUARD_STATS, V_$MANAGED_STANDBY
--------------------------------------------------------------------------------
SELECT database_role, open_mode, switchover_status FROM v$database;
SELECT name, value FROM v$dataguard_stats;
SELECT process, status, sequence# FROM v$managed_standby WHERE process LIKE 'MRP%';

PROMPT
PROMPT === End of query: Standby snapshot ===
PROMPT

-- End of file
