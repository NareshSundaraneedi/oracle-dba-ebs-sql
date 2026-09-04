--------------------------------------------------------------------------------
-- File Name       : 05_password_expiry.sql
-- Category        : 03_Users_Security
-- Purpose         : Forecast password expiry for OPEN accounts
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows days until EXPIRY_DATE for OPEN users so you can act before
-- batch accounts lock out.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Days until password expiry
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes EXPIRY_DATE - SYSDATE for OPEN users with an expiry.
-- 2. Important columns
--    USERNAME, EXPIRY_DATE, DAYS_LEFT, PROFILE.
-- 3. How to interpret the output
--    NULL expiry means UNLIMITED life time or non-password auth.
-- 4. What indicates a problem
--    DAYS_LEFT < 14 for a service account.
-- 5. Recommended DBA action
--    Adjust profile or rotate the password in a planned change. EBS schemas: follow MOS password-change notes.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_USERS
--------------------------------------------------------------------------------
SELECT
       username,
       account_status,
       profile,
       expiry_date,
       ROUND(expiry_date - SYSDATE) AS days_left,
       CASE
         WHEN expiry_date IS NULL THEN 'NO_EXPIRY'
         WHEN expiry_date - SYSDATE < 0 THEN 'EXPIRED'
         WHEN expiry_date - SYSDATE < 7 THEN 'CRITICAL'
         WHEN expiry_date - SYSDATE < 14 THEN 'WARNING'
         WHEN expiry_date - SYSDATE < 30 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_users
WHERE  account_status = 'OPEN'
ORDER BY expiry_date NULLS LAST, username;

PROMPT
PROMPT === End of query: Days until password expiry ===
PROMPT

-- End of file
