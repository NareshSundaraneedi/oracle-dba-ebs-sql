--------------------------------------------------------------------------------
-- File Name       : 04_expired_users.sql
-- Category        : 03_Users_Security
-- Purpose         : List expired and expired-grace accounts
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Password expiry on APPS/APPLSYS/SYSADMIN-related schemas is a
-- self-inflicted EBS outage. Catch it before the grace period ends.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Expired and grace users
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_USERS for EXPIRED statuses.
-- 2. Important columns
--    USERNAME, ACCOUNT_STATUS, EXPIRY_DATE, PROFILE.
-- 3. How to interpret the output
--    EXPIRED(GRACE) can still log in but will be prompted to change password — batch accounts cannot do that.
-- 4. What indicates a problem
--    APPS in EXPIRED(GRACE) — concurrent managers will start failing as connections recycle.
-- 5. Recommended DBA action
--    For service accounts, use a profile with PASSWORD_LIFE_TIME UNLIMITED. Password changes for EBS schemas follow Oracle EBS documentation only.
-- 6. Production cautions
--    Never expire or reset EBS product schema passwords with generic ALTER USER without the official supported method.
-- 7. Required privileges
--    SELECT on DBA_USERS
-- EBS relevance  : Critical for EBS
--------------------------------------------------------------------------------
SELECT
       username,
       account_status,
       expiry_date,
       profile,
       default_tablespace
FROM   dba_users
WHERE  account_status LIKE '%EXPIRED%'
ORDER BY expiry_date, username;

PROMPT
PROMPT === End of query: Expired and grace users ===
PROMPT

-- End of file
