--------------------------------------------------------------------------------
-- File Name       : 14_role_privileges.sql
-- Category        : 03_Users_Security
-- Purpose         : Expand privileges a role conveys
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows system and object privileges granted to a role, plus nested roles.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Privileges granted to a role
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads ROLE_SYS_PRIVS, ROLE_TAB_PRIVS, ROLE_ROLE_PRIVS.
-- 2. Important columns
--    ROLE, PRIVILEGE, OWNER, TABLE_NAME, GRANTED_ROLE.
-- 3. How to interpret the output
--    Nested roles hide DBA-like access. Expand fully before certifying a user.
-- 4. What indicates a problem
--    A 'read only' role that includes UPDATE via a nested role.
-- 5. Recommended DBA action
--    Rebuild the role with least privilege.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on ROLE_SYS_PRIVS, ROLE_TAB_PRIVS, ROLE_ROLE_PRIVS
--------------------------------------------------------------------------------
DEFINE role_p = DBA

SELECT role, privilege, admin_option
FROM   role_sys_privs
WHERE  role = '&role_p'
ORDER BY privilege;

SELECT role, owner, table_name, column_name, privilege, grantable
FROM   role_tab_privs
WHERE  role = '&role_p'
AND    ROWNUM <= 200
ORDER BY owner, table_name;

SELECT role, granted_role, admin_option
FROM   role_role_privs
WHERE  role = '&role_p'
ORDER BY granted_role;

PROMPT
PROMPT === End of query: Privileges granted to a role ===
PROMPT

-- End of file
