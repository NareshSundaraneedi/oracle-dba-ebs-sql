--------------------------------------------------------------------------------
-- File Name       : 08_last_login.sql
-- Category        : 03_Users_Security
-- Purpose         : Show last login time (12c+ DBA_USERS.LAST_LOGIN)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- LAST_LOGIN is populated when the initialization parameter
-- MAX_IDLE_TIME related tracking / 12.1+ last login feature is available.
-- On 19c it is in DBA_USERS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Last login for non-Oracle-maintained users
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_USERS.LAST_LOGIN (12.1+).
-- 2. Important columns
--    USERNAME, LAST_LOGIN, ACCOUNT_STATUS.
-- 3. How to interpret the output
--    NULL last login can mean the account has never logged in since the feature was available, or is used only via proxy.
-- 4. What indicates a problem
--    Interactive DBA accounts unused for 180+ days still OPEN.
-- 5. Recommended DBA action
--    Lock stale named accounts after owner confirmation.
-- 6. Production cautions
--    Safe. LAST_LOGIN requires Oracle 12.1+ (present on 19c).
-- 7. Required privileges
--    SELECT on DBA_USERS
--
-- Oracle 19c (LAST_LOGIN column).
--------------------------------------------------------------------------------
SELECT
       username,
       last_login,
       account_status,
       created,
       profile
FROM   dba_users
WHERE  oracle_maintained = 'N'
ORDER BY last_login DESC NULLS LAST;

PROMPT
PROMPT === End of query: Last login for non-Oracle-maintained users ===
PROMPT

-- End of file
