--------------------------------------------------------------------------------
-- File Name       : 07_ebs_users.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : FND_USER application users (not database users)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- EBS end users live in FND_USER. Difference vs 27_EBS_Users: this is a basic inventory; folder 27 has end-date, responsibilities, and hygiene.
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
-- QUERY 1: FND users sample and counts
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_USER counts and recently created.
-- 2. Important columns
--    USER_NAME, EMAIL, END_DATE, LAST_LOGON.
-- 3. How to interpret the output
--    END_DATE < SYSDATE means the user cannot log in.
-- 4. What indicates a problem
--    SYSADMIN end-dated. Guest user modified.
-- 5. Recommended DBA action
--    Use the Users form / User Management. Do not UPDATE FND_USER.END_DATE by SQL except with approved procedure.
-- 6. Production cautions
--    Safe. Do not dump all password hashes.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT COUNT(*) total_users,
       SUM(CASE WHEN NVL(end_date,SYSDATE+1) > SYSDATE THEN 1 ELSE 0 END) active_users
FROM fnd_user;

SELECT user_name, description, email_address, start_date, end_date, last_logon_date
FROM fnd_user
ORDER BY NVL(last_logon_date, start_date) DESC
FETCH FIRST 50 ROWS ONLY;

PROMPT
PROMPT === End of query: FND users sample and counts ===
PROMPT

-- End of file
