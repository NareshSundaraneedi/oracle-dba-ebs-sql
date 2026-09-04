--------------------------------------------------------------------------------
-- File Name       : 10_responsibility_assignments.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Who has a given responsibility (SoD helper)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE resp_name. Used for System Administrator / GL Super User reviews.
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
-- QUERY 1: Users of one responsibility
--------------------------------------------------------------------------------
-- 1. What the query does
--    Direct assignments still effective.
-- 2. Important columns
--    USER_NAME, START_DATE, END_DATE.
-- 3. How to interpret the output
--    Include only NVL(end_date,future)>SYSDATE.
-- 4. What indicates a problem
--    Too many users with a privileged resp.
-- 5. Recommended DBA action
--    Revoke via form.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE resp_name = System Administrator
SELECT u.user_name, urg.start_date, urg.end_date, u.email_address
FROM fnd_user_resp_groups_direct urg
JOIN fnd_user u ON u.user_id=urg.user_id
JOIN fnd_responsibility_vl r ON r.responsibility_id=urg.responsibility_id AND r.application_id=urg.responsibility_application_id
WHERE r.responsibility_name='&resp_name'
AND NVL(urg.end_date,SYSDATE+1)>SYSDATE AND NVL(u.end_date,SYSDATE+1)>SYSDATE
ORDER BY u.user_name;

PROMPT
PROMPT === End of query: Users of one responsibility ===
PROMPT

-- End of file
