--------------------------------------------------------------------------------
-- File Name       : 13_dependencies.sql
-- Category        : 05_Objects
-- Purpose         : Show dependencies for one object
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Used before dropping or altering a custom object.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Dependencies of one object
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_DEPENDENCIES in both directions.
-- 2. Important columns
--    NAME, TYPE, REFERENCED_NAME, REFERENCED_TYPE.
-- 3. How to interpret the output
--    Hard dependencies must be recompiled after a change.
-- 4. What indicates a problem
--    A custom view depended on by many concurrent programs.
-- 5. Recommended DBA action
--    Impact-assess before DDL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_DEPENDENCIES
--------------------------------------------------------------------------------
DEFINE owner_p = XXCUST
DEFINE name_p  = XX_CUSTOM_PKG

SELECT owner, name, type, referenced_owner, referenced_name, referenced_type, referenced_link_name, dependency_type
FROM   dba_dependencies
WHERE  owner = '&owner_p' AND name = '&name_p'
ORDER BY referenced_owner, referenced_name;

SELECT owner, name, type, referenced_owner, referenced_name, referenced_type
FROM   dba_dependencies
WHERE  referenced_owner = '&owner_p' AND referenced_name = '&name_p'
ORDER BY owner, name;

PROMPT
PROMPT === End of query: Dependencies of one object ===
PROMPT

-- End of file
