--------------------------------------------------------------------------------
-- File Name       : 04_user_responsibilities.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Responsibilities assigned to one user
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE username. Direct assignments (FND_USER_RESP_GROUPS_DIRECT).
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
-- QUERY 1: Assignments
--------------------------------------------------------------------------------
-- 1. What the query does
--    User to resp with dates.
-- 2. Important columns
--    RESPONSIBILITY_NAME, START_DATE, END_DATE.
-- 3. How to interpret the output
--    END_DATE past = assignment inactive.
-- 4. What indicates a problem
--    User has System Administrator unexpectedly.
-- 5. Recommended DBA action
--    Revoke via form / UMX.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE username = SYSADMIN
SELECT u.user_name, r.responsibility_name, urg.start_date, urg.end_date
FROM fnd_user u
JOIN fnd_user_resp_groups_direct urg ON urg.user_id=u.user_id
JOIN fnd_responsibility_vl r ON r.responsibility_id=urg.responsibility_id AND r.application_id=urg.responsibility_application_id
WHERE u.user_name='&username'
ORDER BY r.responsibility_name;

PROMPT
PROMPT === End of query: Assignments ===
PROMPT

-- End of file
