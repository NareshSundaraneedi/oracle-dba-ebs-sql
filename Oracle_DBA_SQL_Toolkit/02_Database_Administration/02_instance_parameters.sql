--------------------------------------------------------------------------------
-- File Name       : 02_instance_parameters.sql
-- Category        : 02_Database_Administration
-- Purpose         : Show all initialization parameters with session/system modify flags
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Full parameter listing for audits and clone comparisons. Filter in SQL*Plus
-- with a substitution variable if needed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: All parameters (optionally filtered)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$PARAMETER. Uncomment the LIKE filter to search.
-- 2. Important columns
--    NAME, VALUE, ISDEFAULT, ISSYS_MODIFIABLE, ISSES_MODIFIABLE.
-- 3. How to interpret the output
--    IMMEDIATE can be changed with ALTER SYSTEM. FALSE requires a bounce.
-- 4. What indicates a problem
--    A memory-only change that will vanish on restart (ISMODIFIED = SYSTEM_MOD and not in SPFILE).
-- 5. Recommended DBA action
--    Document intended values. Persist with SCOPE=SPFILE/BOTH in a change window.
-- 6. Production cautions
--    Safe. Do not ALTER SYSTEM here. This result set is large.
-- 7. Required privileges
--    SELECT on V_$PARAMETER
--------------------------------------------------------------------------------
-- Optional: DEFINE pname = %process%
SELECT
       name,
       display_value,
       isdefault,
       issys_modifiable,
       isses_modifiable,
       ismodified,
       isadjusted,
       description
FROM   v$parameter
-- WHERE name LIKE '&pname'
ORDER BY name;

PROMPT
PROMPT === End of query: All parameters (optionally filtered) ===
PROMPT

-- End of file
