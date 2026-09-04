--------------------------------------------------------------------------------
-- File Name       : 01_running_requests.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Currently running concurrent requests with elapsed time
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Live running list. Join to session if oracle_session_id is populated (25_EBS).
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
-- QUERY 1: Running requests
--------------------------------------------------------------------------------
-- 1. What the query does
--    PHASE_CODE R.
-- 2. Important columns
--    REQUEST_ID, PROGRAM, USER, MINUTES, ORACLE_SESSION_ID, PARENT.
-- 3. How to interpret the output
--    ORACLE_SESSION_ID is the SID (not always filled immediately).
-- 4. What indicates a problem
--    A request running many times longer than its average (13/14).
-- 5. Recommended DBA action
--    Folder 25 step 1-3. Do not cancel without functional approval.
-- 6. Production cautions
--    Safe. Cancelling is a functional action.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       r.request_id,
       p.user_concurrent_program_name,
       u.user_name,
       r.phase_code,
       r.status_code,
       r.request_date,
       r.actual_start_date,
       ROUND((SYSDATE-r.actual_start_date)*24*60,1) AS minutes_running,
       r.oracle_session_id,
       r.oracle_process_id,
       r.parent_request_id,
       r.logfile_name,
       r.outfile_name
FROM   fnd_concurrent_requests r
JOIN   fnd_concurrent_programs_vl p
       ON p.concurrent_program_id = r.concurrent_program_id
      AND p.application_id = r.program_application_id
JOIN   fnd_user u ON u.user_id = r.requested_by
WHERE  r.phase_code = 'R'
ORDER BY r.actual_start_date;

PROMPT
PROMPT === End of query: Running requests ===
PROMPT

-- End of file
