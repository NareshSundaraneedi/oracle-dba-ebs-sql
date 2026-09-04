--------------------------------------------------------------------------------
-- File Name       : 11_roles.sql
-- Category        : 03_Users_Security
-- Purpose         : List roles and role grants to users
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows DBA_ROLES and DBA_ROLE_PRIVS. DBA, SYSDBA-equivalent roles
-- on named users are a critical finding.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Roles and who has them
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_ROLES and DBA_ROLE_PRIVS.
-- 2. Important columns
--    ROLE, GRANTEE, ADMIN_OPTION, DEFAULT_ROLE.
-- 3. How to interpret the output
--    ADMIN_OPTION YES means the grantee can grant the role onward.
-- 4. What indicates a problem
--    DBA granted to an application user or PUBLIC.
-- 5. Recommended DBA action
--    Revoke after impact analysis. Generated revoke only.
-- 6. Production cautions
--    WARNING: REVOKE is destructive to privileges. Generated only.
-- 7. Required privileges
--    SELECT on DBA_ROLES, DBA_ROLE_PRIVS
--------------------------------------------------------------------------------
SELECT role, authentication_type, common, oracle_maintained
FROM   dba_roles
ORDER BY role;

SELECT grantee, granted_role, admin_option, delegate_option, default_role, common
FROM   dba_role_privs
WHERE  granted_role IN ('DBA','SYSDBA','DATAPUMP_IMP_FULL_DATABASE','IMP_FULL_DATABASE','EXP_FULL_DATABASE','SELECT_CATALOG_ROLE')
OR     grantee NOT IN (SELECT role FROM dba_roles)
ORDER BY granted_role, grantee;

PROMPT
PROMPT === End of query: Roles and who has them ===
PROMPT

-- End of file
