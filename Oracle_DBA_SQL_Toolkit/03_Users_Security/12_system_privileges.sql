--------------------------------------------------------------------------------
-- File Name       : 12_system_privileges.sql
-- Category        : 03_Users_Security
-- Purpose         : List powerful system privileges
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Focuses on dangerous privileges: ANY, DBA-like, GRANT ANY, ALTER USER.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: High-risk system privileges
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_SYS_PRIVS for ANY / ADMIN / GRANT privileges.
-- 2. Important columns
--    GRANTEE, PRIVILEGE, ADMIN_OPTION.
-- 3. How to interpret the output
--    ANY privileges bypass schema isolation. PUBLIC should have almost none.
-- 4. What indicates a problem
--    GRANT ANY PRIVILEGE or SELECT ANY TABLE on an app user.
-- 5. Recommended DBA action
--    Revoke after confirming nothing depends on it. Generated only.
-- 6. Production cautions
--    WARNING: REVOKE generated only.
-- 7. Required privileges
--    SELECT on DBA_SYS_PRIVS
--------------------------------------------------------------------------------
SELECT
       grantee,
       privilege,
       admin_option,
       common
FROM   dba_sys_privs
WHERE  privilege LIKE '%ANY%'
OR     privilege IN ('GRANT ANY PRIVILEGE','GRANT ANY ROLE','GRANT ANY OBJECT PRIVILEGE',
                     'ALTER USER','DROP USER','BECOME USER','ALTER SYSTEM','ALTER DATABASE',
                     'EXEMPT ACCESS POLICY','EXEMPT REDACTION POLICY')
ORDER BY privilege, grantee;

PROMPT
PROMPT === End of query: High-risk system privileges ===
PROMPT

-- End of file
