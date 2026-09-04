--------------------------------------------------------------------------------
-- File Name       : 01_ebs_users.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : FND_USER inventory (active vs end-dated)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Application users. Difference vs 20/07: active filter and last_logon hygiene.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: User counts and recent logons
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_USER.
-- 2. Important columns
--    USER_NAME, END_DATE, LAST_LOGON.
-- 3. How to interpret the output
--    END_DATE not null and < SYSDATE = cannot log in.
-- 4. What indicates a problem
--    SYSADMIN end-dated.
-- 5. Recommended DBA action
--    Users form — no SQL update.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT user_name, description, email_address, start_date, end_date, last_logon_date
FROM fnd_user WHERE NVL(end_date,SYSDATE+1) > SYSDATE
ORDER BY last_logon_date DESC NULLS LAST FETCH FIRST 100 ROWS ONLY;

PROMPT
PROMPT === End of query: User counts and recent logons ===
PROMPT

-- End of file
