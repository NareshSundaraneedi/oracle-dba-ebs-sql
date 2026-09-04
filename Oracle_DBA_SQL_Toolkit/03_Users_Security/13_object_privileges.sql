--------------------------------------------------------------------------------
-- File Name       : 13_object_privileges.sql
-- Category        : 03_Users_Security
-- Purpose         : List object grants for a schema or grantee
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Parameterized object privilege search. Use for APPS grants and
-- custom XX users.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Object privileges filtered by owner or grantee
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_TAB_PRIVS with bind/substitution filters.
-- 2. Important columns
--    GRANTEE, OWNER, TABLE_NAME, PRIVILEGE, GRANTABLE.
-- 3. How to interpret the output
--    GRANTABLE YES means the grantee can pass the privilege on.
-- 4. What indicates a problem
--    PUBLIC SELECT on a table with PII. Unexpected DELETE on a setup table.
-- 5. Recommended DBA action
--    Revoke after impact analysis. Generated only.
-- 6. Production cautions
--    Result set can be huge on EBS. Always filter.
-- 7. Required privileges
--    SELECT on DBA_TAB_PRIVS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
-- Set one or both filters
DEFINE grantee_p = APPS
DEFINE owner_p   = GL

SELECT
       grantee,
       owner,
       table_name,
       privilege,
       grantable,
       type
FROM   dba_tab_privs
WHERE  (grantee = '&grantee_p' OR '&grantee_p' IS NULL)
AND    (owner = '&owner_p' OR '&owner_p' IS NULL)
AND    ROWNUM <= 500
ORDER BY owner, table_name, grantee, privilege;

PROMPT
PROMPT === End of query: Object privileges filtered by owner or grantee ===
PROMPT

-- End of file
