--------------------------------------------------------------------------------
-- File Name       : 15_grants.sql
-- Category        : 03_Users_Security
-- Purpose         : Show all privilege paths for one user (roles + direct grants)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Single-user privilege dump used during joiner/mover/leaver reviews.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Direct grants and granted roles for one user
--------------------------------------------------------------------------------
-- 1. What the query does
--    Combines DBA_SYS_PRIVS, DBA_TAB_PRIVS, DBA_ROLE_PRIVS for a username.
-- 2. Important columns
--    PRIV_TYPE, PRIVILEGE, OWNER, TABLE_NAME.
-- 3. How to interpret the output
--    This is one level deep. Recurse roles with 14_role_privileges.sql.
-- 4. What indicates a problem
--    User has both an application role and DBA.
-- 5. Recommended DBA action
--    Revoke excess after approval.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_SYS_PRIVS, DBA_TAB_PRIVS, DBA_ROLE_PRIVS
--------------------------------------------------------------------------------
DEFINE uname = SCOTT

SELECT 'SYS' AS priv_type, privilege, TO_CHAR(NULL) AS owner, TO_CHAR(NULL) AS table_name, admin_option AS extra
FROM   dba_sys_privs
WHERE  grantee = '&uname'
UNION ALL
SELECT 'TAB', privilege, owner, table_name, grantable
FROM   dba_tab_privs
WHERE  grantee = '&uname'
UNION ALL
SELECT 'ROLE', granted_role, NULL, NULL, admin_option
FROM   dba_role_privs
WHERE  grantee = '&uname'
ORDER BY 1, 2;

PROMPT
PROMPT === End of query: Direct grants and granted roles for one user ===
PROMPT

-- End of file
