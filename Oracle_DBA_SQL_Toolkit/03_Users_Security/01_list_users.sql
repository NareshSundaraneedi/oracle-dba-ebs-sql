--------------------------------------------------------------------------------
-- File Name       : 01_list_users.sql
-- Category        : 03_Users_Security
-- Purpose         : List all database users with default tablespace and profile
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Inventory of DBA_USERS. On EBS this includes product schemas (GL, AR,
-- APPS, APPLSYS) plus named application users if they have DB accounts.
-- Most EBS end users are FND_USER rows, not database users.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: All database users
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_USERS.
-- 2. Important columns
--    USERNAME, ACCOUNT_STATUS, CREATED, PROFILE, DEFAULT_TABLESPACE, AUTHENTICATION_TYPE.
-- 3. How to interpret the output
--    AUTHENTICATION_TYPE PASSWORD vs EXTERNAL vs NONE. EBS product schemas should remain LOCKED except APPS/APPLSYS/etc. that must be open.
-- 4. What indicates a problem
--    Unexpected OPEN users created outside change control. Default tablespace SYSTEM.
-- 5. Recommended DBA action
--    Lock unused accounts with approval. Do not drop users from this script.
-- 6. Production cautions
--    Safe. EBS schema passwords are tightly controlled — do not reset them here.
-- 7. Required privileges
--    SELECT on DBA_USERS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       username,
       user_id,
       account_status,
       lock_date,
       expiry_date,
       created,
       profile,
       default_tablespace,
       temporary_tablespace,
       authentication_type,
       oracle_maintained,
       common
FROM   dba_users
ORDER BY username;

PROMPT
PROMPT === End of query: All database users ===
PROMPT

-- End of file
