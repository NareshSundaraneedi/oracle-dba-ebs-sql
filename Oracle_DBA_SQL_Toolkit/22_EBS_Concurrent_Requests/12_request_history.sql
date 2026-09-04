--------------------------------------------------------------------------------
-- File Name       : 12_request_history.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : One request_id full history row (arguments, log, parent)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE request_id. The 'open this ticket' query.
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
-- QUERY 1: Single request
--------------------------------------------------------------------------------
-- 1. What the query does
--    Full FND_CONCURRENT_REQUESTS row plus program/user.
-- 2. Important columns
--    All key request attributes.
-- 3. How to interpret the output
--    ARGUMENT_TEXT is the submitted parameters. PARENT_REQUEST_ID walks a set.
-- 4. What indicates a problem
--    N/A — lookup.
-- 5. Recommended DBA action
--    If running, take ORACLE_SESSION_ID to 25/02.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE request_id = 0

SELECT r.request_id, r.parent_request_id, r.priority, r.phase_code, r.status_code,
       r.hold_flag, r.requested_start_date, r.actual_start_date, r.actual_completion_date,
       r.oracle_session_id, r.oracle_process_id, r.os_process_id,
       r.logfile_name, r.outfile_name, r.completion_text,
       r.argument_text,
       p.concurrent_program_name, p.user_concurrent_program_name,
       u.user_name, resp.responsibility_name
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
LEFT JOIN fnd_responsibility_tl resp ON resp.responsibility_id=r.responsibility_id AND resp.language=USERENV('LANG')
WHERE r.request_id = &request_id;

PROMPT
PROMPT === End of query: Single request ===
PROMPT

-- End of file
