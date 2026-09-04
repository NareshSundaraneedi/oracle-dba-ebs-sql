--------------------------------------------------------------------------------
-- File Name       : 07_diagnostic_dest.sql
-- Category        : 02_Database_Administration
-- Purpose         : Show diagnostic_dest and ADR size pressure
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ADR can fill the volume that holds DIAGNOSTIC_DEST (incidents, cdumps,
-- HM reports). Full ADR does not crash the database but blocks packaging
-- and can fill the disk if it shares ORACLE_BASE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: diagnostic_dest and incident counts
--------------------------------------------------------------------------------
-- 1. What the query does
--    Shows diagnostic_dest and active problem/incident counts from V$DIAG_INFO.
-- 2. Important columns
--    DIAGNOSTIC_DEST, Active Problem Count, Active Incident Count.
-- 3. How to interpret the output
--    A rising incident count after ORA-00600/07445 storms needs purge (adrci) and root-cause work.
-- 4. What indicates a problem
--    Active Incident Count in the hundreds. diagnostic_dest on a small root volume.
-- 5. Recommended DBA action
--    Use adrci purge after capturing needed incidents. Move diagnostic_dest only with a bounce and a plan.
-- 6. Production cautions
--    Safe. adrci purge is an operational action — not executed here.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$DIAG_INFO
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter WHERE name = 'diagnostic_dest';

SELECT name, value
FROM   v$diag_info
WHERE  name IN ('ADR Base','ADR Home','Active Problem Count','Active Incident Count');

PROMPT
PROMPT === End of query: diagnostic_dest and incident counts ===
PROMPT

-- End of file
