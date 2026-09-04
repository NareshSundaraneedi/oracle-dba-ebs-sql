--------------------------------------------------------------------------------
-- File Name       : 20_security_checks.sql
-- Category        : 03_Users_Security
-- Purpose         : Packaged security hygiene checks for a production database
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- A short checklist: default passwords (where detectable), PUBLIC
-- dangerous grants, users with DBA, and remote_os_authent.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: High-value security findings
--------------------------------------------------------------------------------
-- 1. What the query does
--    Several small queries that flag common production issues.
-- 2. Important columns
--    FINDING, DETAIL.
-- 3. How to interpret the output
--    Each row is a finding to review, not automatically a vulnerability.
-- 4. What indicates a problem
--    ANY of: DBA on non-DBA named users, PUBLIC UTL_FILE, remote_os_authent TRUE.
-- 5. Recommended DBA action
--    Remediate via change control. Do not revoke PUBLIC grants blindly on EBS — APPS depends on many of them.
-- 6. Production cautions
--    EBS requires specific PUBLIC and APPS grants. Compare against a known-good EBS baseline before revoking.
-- 7. Required privileges
--    SELECT on DBA_ROLE_PRIVS, DBA_TAB_PRIVS, DBA_USERS, V_$PARAMETER
-- EBS relevance  : Review carefully on EBS
--------------------------------------------------------------------------------
SELECT 'DBA_ROLE' AS finding, grantee AS detail
FROM   dba_role_privs
WHERE  granted_role = 'DBA'
AND    grantee NOT IN ('SYS','SYSTEM')
UNION ALL
SELECT 'PUBLIC_UTL', table_name || ' ' || privilege
FROM   dba_tab_privs
WHERE  grantee = 'PUBLIC'
AND    table_name IN ('UTL_FILE','UTL_HTTP','UTL_SMTP','UTL_TCP','DBMS_JAVA','DBMS_SCHEDULER')
UNION ALL
SELECT 'PARAM', name || '=' || value
FROM   v$parameter
WHERE  name IN ('remote_os_authent','os_authent_prefix','sec_case_sensitive_logon','audit_trail','unified_audit_systemlog')
UNION ALL
SELECT 'OPEN_ORACLE_MAINTAINED', username
FROM   dba_users
WHERE  oracle_maintained = 'Y'
AND    account_status = 'OPEN'
AND    username NOT IN ('SYS','SYSTEM','AUDSYS','GSMUSER','DBSFWUSER','REMOTE_SCHEDULER_AGENT','SYSRAC','SYSBACKUP','SYSDG','SYSKM')
ORDER BY 1, 2;

PROMPT
PROMPT === End of query: High-value security findings ===
PROMPT

-- End of file
