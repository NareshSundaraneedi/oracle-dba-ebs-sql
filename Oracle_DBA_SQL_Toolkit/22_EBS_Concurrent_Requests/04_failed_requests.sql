--------------------------------------------------------------------------------
-- File Name       : 04_failed_requests.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Error / warning / terminated requests
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- STATUS E, G, X. Start of every morning check.
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
-- QUERY 1: Failed last N hours
--------------------------------------------------------------------------------
-- 1. What the query does
--    Completed with error/warning/terminated.
-- 2. Important columns
--    REQUEST_ID, STATUS, PROGRAM, LOGFILE.
-- 3. How to interpret the output
--    E needs the request log. G may still have produced output.
-- 4. What indicates a problem
--    A critical period close program in E.
-- 5. Recommended DBA action
--    Read logfile on the concurrent node. Then 25 if it was long-running before fail.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE hours = 24

SELECT r.request_id, r.status_code, p.user_concurrent_program_name, u.user_name,
       r.actual_start_date, r.actual_completion_date,
       r.completion_text, r.logfile_name
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='C'
AND r.status_code IN ('E','G','X')
AND NVL(r.actual_completion_date,r.request_date) > SYSDATE - &hours/24
ORDER BY r.actual_completion_date DESC;

PROMPT
PROMPT === End of query: Failed last N hours ===
PROMPT

-- End of file
