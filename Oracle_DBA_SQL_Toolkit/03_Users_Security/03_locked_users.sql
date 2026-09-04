--------------------------------------------------------------------------------
-- File Name       : 03_locked_users.sql
-- Category        : 03_Users_Security
-- Purpose         : List locked accounts and lock dates
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows locked users. Distinguish administrative locks from
-- FAILED_LOGIN locks (LOCKED(TIMED)).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Locked users
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_USERS for lock statuses.
-- 2. Important columns
--    USERNAME, ACCOUNT_STATUS, LOCK_DATE, PROFILE.
-- 3. How to interpret the output
--    LOCKED(TIMED) is usually failed-login lockout and may expire. LOCKED is an explicit lock.
-- 4. What indicates a problem
--    APPS or a batch schema unexpectedly LOCKED — EBS will fail immediately.
-- 5. Recommended DBA action
--    If a required schema is locked, unlock only with approval: ALTER USER x ACCOUNT UNLOCK; — generated, not executed.
-- 6. Production cautions
--    WARNING: Unlock is a security-sensitive change. Generated only.
-- 7. Required privileges
--    SELECT on DBA_USERS
--------------------------------------------------------------------------------
SELECT
       username,
       account_status,
       lock_date,
       expiry_date,
       profile,
       oracle_maintained
FROM   dba_users
WHERE  account_status LIKE '%LOCK%'
ORDER BY lock_date DESC NULLS LAST, username;

-- WARNING: Review carefully before executing.
SELECT 'ALTER USER "' || username || '" ACCOUNT UNLOCK;' AS unlock_cmd
FROM   dba_users
WHERE  account_status LIKE '%LOCK%'
AND    oracle_maintained = 'N';

PROMPT
PROMPT === End of query: Locked users ===
PROMPT

-- End of file
