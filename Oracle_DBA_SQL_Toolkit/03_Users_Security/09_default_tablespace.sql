--------------------------------------------------------------------------------
-- File Name       : 09_default_tablespace.sql
-- Category        : 03_Users_Security
-- Purpose         : Find users whose default tablespace is SYSTEM or SYSAUX
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Application users must not default to SYSTEM. Space and recovery
-- impact if they create objects there.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Default tablespace assignment
--------------------------------------------------------------------------------
-- 1. What the query does
--    Groups users by default tablespace and flags SYSTEM/SYSAUX.
-- 2. Important columns
--    USERNAME, DEFAULT_TABLESPACE, TEMPORARY_TABLESPACE.
-- 3. How to interpret the output
--    Only SYS should normally use SYSTEM as default.
-- 4. What indicates a problem
--    APPS or custom user defaulting to SYSTEM.
-- 5. Recommended DBA action
--    ALTER USER x DEFAULT TABLESPACE <correct> — generated only.
-- 6. Production cautions
--    WARNING: ALTER USER is a change. Generated only.
-- 7. Required privileges
--    SELECT on DBA_USERS
--------------------------------------------------------------------------------
SELECT
       username,
       default_tablespace,
       temporary_tablespace,
       account_status,
       CASE
         WHEN default_tablespace IN ('SYSTEM','SYSAUX') AND username NOT IN ('SYS','SYSTEM') THEN 'WARNING'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_users
ORDER BY default_tablespace, username;

-- WARNING: Review carefully before executing.
SELECT 'ALTER USER "' || username || '" DEFAULT TABLESPACE USERS;' AS fix_cmd
FROM   dba_users
WHERE  default_tablespace IN ('SYSTEM','SYSAUX')
AND    username NOT IN ('SYS','SYSTEM');

PROMPT
PROMPT === End of query: Default tablespace assignment ===
PROMPT

-- End of file
