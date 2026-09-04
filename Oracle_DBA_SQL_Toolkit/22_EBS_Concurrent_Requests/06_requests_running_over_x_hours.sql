--------------------------------------------------------------------------------
-- File Name       : 06_requests_running_over_x_hours.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Running requests longer than &hours (parameterized)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 05: parameterized threshold for month-end (use 4 or 8).
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
-- QUERY 1: Running over X hours
--------------------------------------------------------------------------------
-- 1. What the query does
--    DEFINE hours filter.
-- 2. Important columns
--    REQUEST_ID, HOURS_RUNNING.
-- 3. How to interpret the output
--    Same as 05 with a knob.
-- 4. What indicates a problem
--    Any row during an SLA window.
-- 5. Recommended DBA action
--    25 master script with :request_id.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE hours = 4

SELECT r.request_id, p.user_concurrent_program_name, u.user_name,
       ROUND((SYSDATE-r.actual_start_date)*24,2) hours_running,
       r.oracle_session_id, r.status_code
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='R'
AND (SYSDATE-r.actual_start_date)*24 >= &hours
ORDER BY r.actual_start_date;

PROMPT
PROMPT === End of query: Running over X hours ===
PROMPT

-- End of file
