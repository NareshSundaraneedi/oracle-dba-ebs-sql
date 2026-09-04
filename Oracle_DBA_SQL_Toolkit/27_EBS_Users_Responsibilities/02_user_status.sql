--------------------------------------------------------------------------------
-- File Name       : 02_user_status.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Users who cannot log in (end-dated / no logon)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- End-dated and never-logged-in users.
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
-- QUERY 1: Inactive application users
--------------------------------------------------------------------------------
-- 1. What the query does
--    END_DATE < SYSDATE or last_logon null and created > 90 days.
-- 2. Important columns
--    USER_NAME, END_DATE.
-- 3. How to interpret the output
--    Never-logged-in service accounts may be OK.
-- 4. What indicates a problem
--    Named humans unused 180 days still active — audit.
-- 5. Recommended DBA action
--    End-date via form after HR confirm.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT user_name, start_date, end_date, last_logon_date
FROM fnd_user
WHERE (end_date IS NOT NULL AND end_date < SYSDATE)
   OR (last_logon_date IS NULL AND start_date < SYSDATE-90)
ORDER BY NVL(end_date,start_date) DESC FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Inactive application users ===
PROMPT

-- End of file
