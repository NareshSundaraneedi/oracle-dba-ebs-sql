--------------------------------------------------------------------------------
-- File Name       : 16_option_status.sql
-- Category        : 02_Database_Administration
-- Purpose         : Show installed Oracle options (RAC, Partitioning, etc.)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$OPTION lists whether options are linked into the binary.
-- VALUE TRUE does not automatically mean you are licensed to use them.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$OPTION inventory
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$OPTION.
-- 2. Important columns
--    PARAMETER, VALUE.
-- 3. How to interpret the output
--    Real Application Clusters TRUE means RAC is linked. Partitioning TRUE is common on EE.
-- 4. What indicates a problem
--    An option you rely on (Partitioning, Advanced Compression) showing FALSE after a relink.
-- 5. Recommended DBA action
--    Relink options only with Support guidance. License questions go to contract management.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$OPTION
--------------------------------------------------------------------------------
SELECT parameter, value
FROM   v$option
ORDER BY parameter;

PROMPT
PROMPT === End of query: V$OPTION inventory ===
PROMPT

-- End of file
