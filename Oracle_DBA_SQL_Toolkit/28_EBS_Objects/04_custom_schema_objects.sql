--------------------------------------------------------------------------------
-- File Name       : 04_custom_schema_objects.sql
-- Category        : 28_EBS_Objects
-- Purpose         : All non-Oracle-maintained schemas that are not product schemas
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds leftover schemas (old XX, tools) that are not in FND_ORACLE_USERID.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Schemas outside FND
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_USERS minus FND_ORACLE_USERID minus oracle_maintained.
-- 2. Important columns
--    USERNAME, CREATED.
-- 3. How to interpret the output
--    May be legitimate tools (RMAN catalog elsewhere). Unexpected OPEN app schemas are findings.
-- 4. What indicates a problem
--    Unknown OPEN schema with tables.
-- 5. Recommended DBA action
--    Security review.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_USERS
--------------------------------------------------------------------------------
SELECT u.username, u.account_status, u.created, u.oracle_maintained
FROM dba_users u
WHERE u.oracle_maintained='N'
AND u.username NOT IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY u.username;

PROMPT
PROMPT === End of query: Schemas outside FND ===
PROMPT

-- End of file
