--------------------------------------------------------------------------------
-- File Name       : 02_user_status.sql
-- Category        : 03_Users_Security
-- Purpose         : Count users by account status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Roll-up of ACCOUNT_STATUS. Use after a security sweep or clone to
-- confirm which accounts are OPEN.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Account status summary
--------------------------------------------------------------------------------
-- 1. What the query does
--    Groups DBA_USERS by ACCOUNT_STATUS.
-- 2. Important columns
--    ACCOUNT_STATUS, USER_COUNT.
-- 3. How to interpret the output
--    OPEN should be a short, known list on a hardened production database.
-- 4. What indicates a problem
--    Many OPEN accounts after a refresh from production to a lower environment without re-locking.
-- 5. Recommended DBA action
--    Compare to the approved open-account baseline.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_USERS
--------------------------------------------------------------------------------
SELECT account_status, COUNT(*) AS user_count
FROM   dba_users
GROUP BY account_status
ORDER BY user_count DESC;

PROMPT
PROMPT === End of query: Account status summary ===
PROMPT

-- End of file
