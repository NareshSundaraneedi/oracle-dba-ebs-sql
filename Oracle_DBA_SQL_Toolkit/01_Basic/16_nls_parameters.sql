--------------------------------------------------------------------------------
-- File Name       : 16_nls_parameters.sql
-- Category        : 01_Basic
-- Purpose         : Compare database, instance, and session NLS settings
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- NLS can be set at database, instance, and session level. Date format
-- and numeric characters differences are a frequent cause of EBS
-- interface errors and concurrent program failures.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database vs session NLS
--------------------------------------------------------------------------------
-- 1. What the query does
--    Compares NLS_DATABASE_PARAMETERS with NLS_SESSION_PARAMETERS.
-- 2. Important columns
--    PARAMETER, DATABASE_VALUE, SESSION_VALUE.
-- 3. How to interpret the output
--    Session values override database defaults. Concurrent managers inherit NLS from the manager environment, not from your SQL*Plus session.
-- 4. What indicates a problem
--    NLS_DATE_FORMAT or NLS_NUMERIC_CHARACTERS differ from what an interface program expects (for example decimal comma).
-- 5. Recommended DBA action
--    Fix the client / concurrent manager environment (NLS_LANG, fnd_concurrent NLS), not the database character set.
-- 6. Production cautions
--    Safe. Changing NLS_DATABASE_PARAMETERS requires rebuild — never done here.
-- 7. Required privileges
--    SELECT on NLS_* views
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       d.parameter,
       d.value AS database_value,
       s.value AS session_value
FROM   nls_database_parameters d
LEFT JOIN nls_session_parameters s
       ON s.parameter = d.parameter
ORDER BY d.parameter;

SELECT parameter, value
FROM   nls_instance_parameters
ORDER BY parameter;

PROMPT
PROMPT === End of query: Database vs session NLS ===
PROMPT

-- End of file
