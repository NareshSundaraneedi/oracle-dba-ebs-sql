--------------------------------------------------------------------------------
-- File Name       : 12_standard_manager.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Standard Manager depth and current requests
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Most unspecialized programs run here. Flooding Standard is a design problem.
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
-- QUERY 1: Standard Manager + current work
--------------------------------------------------------------------------------
-- 1. What the query does
--    STANDARD queue + requests it is running.
-- 2. Important columns
--    RUNNING, REQUEST_ID, PROGRAM.
-- 3. How to interpret the output
--    If all Standard slots run long Gather/Reporting jobs, OLTP requests queue.
-- 4. What indicates a problem
--    Standard 10/10 busy on Gather Schema Stats during peak.
-- 5. Recommended DBA action
--    Specialize long jobs to a night manager. Do not just raise processes without PGA/CPU headroom.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT user_concurrent_queue_name, target_processes, running_processes, sleep_seconds
FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name = 'STANDARD';

SELECT r.request_id, r.phase_code, r.status_code, r.requested_start_date,
       u.user_name, p.user_concurrent_program_name, r.oracle_process_id, r.oracle_session_id
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id = r.concurrent_program_id
 AND p.application_id = r.program_application_id
JOIN fnd_user u ON u.user_id = r.requested_by
JOIN fnd_concurrent_queues q ON q.concurrent_queue_id = r.controlling_manager
WHERE q.concurrent_queue_name = 'STANDARD'
AND r.phase_code = 'R';

PROMPT
PROMPT === End of query: Standard Manager + current work ===
PROMPT

-- End of file
