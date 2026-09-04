--------------------------------------------------------------------------------
-- File Name       : 05_long_running_requests.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Running requests longer than 60 minutes (default)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Fixed 60-minute floor. Use 06 for a bind :hours.
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
-- QUERY 1: Long running
--------------------------------------------------------------------------------
-- 1. What the query does
--    Running and SYSDATE-actual_start_date > 1 hour.
-- 2. Important columns
--    REQUEST_ID, HOURS, PROGRAM, SESSION.
-- 3. How to interpret the output
--    Compare to average runtime (13). A 2-hour program that usually takes 10 minutes is the incident.
-- 4. What indicates a problem
--    Hours_running >> historical average.
-- 5. Recommended DBA action
--    25_EBS_Concurrent_SQL_Troubleshooting.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT r.request_id, p.user_concurrent_program_name, u.user_name,
       ROUND((SYSDATE-r.actual_start_date)*24,2) hours_running,
       r.oracle_session_id, r.oracle_process_id, r.parent_request_id
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='R'
AND (SYSDATE-r.actual_start_date) > 1
ORDER BY r.actual_start_date;

PROMPT
PROMPT === End of query: Long running ===
PROMPT

-- End of file
