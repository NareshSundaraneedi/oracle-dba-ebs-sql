--------------------------------------------------------------------------------
-- File Name       : 08_requests_by_user.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Requests submitted by one FND user
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE username. Finds a user flooding the managers.
--
-- EBS R12.2.x. Run as APPS (or a user with SELECT on APPLSYS/FND and APPS synonyms). Bind variables (:request_id, :hours, :username, :program_name) are provided as SQL*Plus DEFINE where useful.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: By username
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_USER.USER_NAME filter.
-- 2. Important columns
--    REQUEST_ID, PROGRAM, PHASE.
-- 3. How to interpret the output
--    A single user submitting hundreds of reports is a training/schedule issue.
-- 4. What indicates a problem
--    One username owns the entire pending queue.
-- 5. Recommended DBA action
--    Talk to the user. Hold or reschedule — functional.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE username = SYSADMIN

SELECT r.request_id, r.phase_code, r.status_code, p.user_concurrent_program_name,
       r.request_date, r.actual_start_date
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE u.user_name = '&username'
AND r.request_date > SYSDATE-3
ORDER BY r.request_id DESC
FETCH FIRST 100 ROWS ONLY;

PROMPT
PROMPT === End of query: By username ===
PROMPT

-- End of file
