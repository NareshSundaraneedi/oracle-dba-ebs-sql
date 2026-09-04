--------------------------------------------------------------------------------
-- File Name       : 01_ebs_database_information.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : EBS database name, apps user, and character set context
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- First confirmation you are on the intended EBS environment (PROD vs clone).
--
-- Requires EBS R12.2 objects (APPLSYS/APPS). Will fail on a non-EBS database.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database plus APPS user status
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATABASE plus DBA_USERS for APPS/APPLSYS/APPLSYSPUB.
-- 2. Important columns
--    DB_UNIQUE_NAME, APPS STATUS, EXPIRY.
-- 3. How to interpret the output
--    APPS must be OPEN and not in EXPIRED(GRACE) on a running EBS.
-- 4. What indicates a problem
--    APPS locked/expired — login and concurrent processing fail.
-- 5. Recommended DBA action
--    Do not reset APPS password with generic ALTER USER; use the supported EBS password utility (FNDCPASS / AFPASSWD) per MOS.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on V_$DATABASE, DBA_USERS
--------------------------------------------------------------------------------
SELECT name, db_unique_name, database_role, open_mode, log_mode FROM v$database;
SELECT username, account_status, expiry_date, lock_date, profile
FROM dba_users
WHERE username IN ('APPS','APPLSYS','APPLSYSPUB','APPS_NE','SYSTEM')
ORDER BY username;

PROMPT
PROMPT === End of query: Database plus APPS user status ===
PROMPT

-- End of file
