--------------------------------------------------------------------------------
-- File Name       : 07_user_creation_date.sql
-- Category        : 03_Users_Security
-- Purpose         : Show recently created database users
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Detects accounts created outside change control — a common audit finding.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Users created in the last 90 days
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_USERS by CREATED.
-- 2. Important columns
--    USERNAME, CREATED, ACCOUNT_STATUS, ORACLE_MAINTAINED.
-- 3. How to interpret the output
--    ORACLE_MAINTAINED Y users created recently usually mean a component install, not a human account.
-- 4. What indicates a problem
--    An OPEN user created last night with DBA role (check 12_system_privileges.sql).
-- 5. Recommended DBA action
--    Validate against the change ticket. Lock if unauthorized.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_USERS
--------------------------------------------------------------------------------
SELECT
       username,
       created,
       account_status,
       profile,
       oracle_maintained,
       common
FROM   dba_users
WHERE  created > SYSDATE - 90
ORDER BY created DESC;

PROMPT
PROMPT === End of query: Users created in the last 90 days ===
PROMPT

-- End of file
