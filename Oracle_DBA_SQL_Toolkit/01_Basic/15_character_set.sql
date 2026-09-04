--------------------------------------------------------------------------------
-- File Name       : 15_character_set.sql
-- Category        : 01_Basic
-- Purpose         : Show database and national character sets
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- EBS R12.2 commonly uses AL32UTF8. Character set mismatches cause
-- ORA-12705, data corruption on import, and Forms display issues.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database and national character set
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads NLS_DATABASE_PARAMETERS and NLS_CHARACTERSET / NLS_NCHAR_CHARACTERSET.
-- 2. Important columns
--    PARAMETER, VALUE.
-- 3. How to interpret the output
--    NLS_CHARACTERSET is the database character set. NLS_NCHAR_CHARACTERSET is used for NCHAR/NVARCHAR2.
-- 4. What indicates a problem
--    US7ASCII or WE8ISO8859P1 on a database expected to be AL32UTF8. Client NLS_LANG mismatch is a different problem (session, not this query).
-- 5. Recommended DBA action
--    Character set conversion is a project (CSALTER / full export). Never change it as a quick fix.
-- 6. Production cautions
--    Safe. Do not run CSALTER from this toolkit.
-- 7. Required privileges
--    SELECT on NLS_DATABASE_PARAMETERS / V$NLS_PARAMETERS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT parameter, value
FROM   nls_database_parameters
WHERE  parameter IN (
         'NLS_CHARACTERSET',
         'NLS_NCHAR_CHARACTERSET',
         'NLS_LANGUAGE',
         'NLS_TERRITORY',
         'NLS_LENGTH_SEMANTICS',
         'NLS_RDBMS_VERSION'
       )
ORDER BY parameter;

PROMPT
PROMPT === End of query: Database and national character set ===
PROMPT

-- End of file
