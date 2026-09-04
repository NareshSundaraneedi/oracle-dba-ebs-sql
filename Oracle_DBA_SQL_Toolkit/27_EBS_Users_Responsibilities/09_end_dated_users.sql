--------------------------------------------------------------------------------
-- File Name       : 09_end_dated_users.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Recently end-dated users (leaver check)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Who was disabled recently.
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
-- QUERY 1: Recent end dates
--------------------------------------------------------------------------------
-- 1. What the query does
--    END_DATE last 30 days.
-- 2. Important columns
--    USER_NAME, END_DATE.
-- 3. How to interpret the output
--    Compare to HR terminations.
-- 4. What indicates a problem
--    Leaver still active (not in this list).
-- 5. Recommended DBA action
--    08.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT user_name, end_date, last_logon_date FROM fnd_user
WHERE end_date BETWEEN SYSDATE-30 AND SYSDATE+1
ORDER BY end_date DESC;

PROMPT
PROMPT === End of query: Recent end dates ===
PROMPT

-- End of file
