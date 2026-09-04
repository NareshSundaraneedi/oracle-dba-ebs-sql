--------------------------------------------------------------------------------
-- File Name       : 13_conflict_resolution_manager.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Conflict Resolution Manager (incompatibilities / Standby)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- CRM handles incompatible programs. Pending/Standby (status Q) waits for CRM. If CRM is down, Standby never clears.
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
-- QUERY 1: CRM and Standby requests
--------------------------------------------------------------------------------
-- 1. What the query does
--    FNDCRM status + requests in Pending Standby.
-- 2. Important columns
--    CRM RUNNING, REQUEST_ID, PROGRAM, STATUS Q.
-- 3. How to interpret the output
--    Status Q = Standby (incompatible). Status I = scheduled. Status A = waiting (unavailable manager).
-- 4. What indicates a problem
--    CRM down + many Q — backlog will not release.
-- 5. Recommended DBA action
--    Start CRM. Review incompatibilities in Define Program. Do not blindly delete incompatibilities.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT user_concurrent_queue_name, target_processes, running_processes
FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name = 'FNDCRM';

SELECT r.request_id, r.status_code, r.phase_code, r.requested_start_date,
       p.user_concurrent_program_name, u.user_name
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id = r.concurrent_program_id
 AND p.application_id = r.program_application_id
JOIN fnd_user u ON u.user_id = r.requested_by
WHERE r.phase_code = 'P' AND r.status_code = 'Q'
ORDER BY r.requested_start_date
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: CRM and Standby requests ===
PROMPT

-- End of file
