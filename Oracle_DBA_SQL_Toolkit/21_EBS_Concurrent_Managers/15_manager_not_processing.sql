--------------------------------------------------------------------------------
-- File Name       : 15_manager_not_processing.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Why a manager is not picking up requests — checklist query
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Combines the usual reasons: manager down, wrong node, specialization, pending standby, run-alone, requested_start_date future, hold flag.
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
-- QUERY 1: Diagnostic checklist
--------------------------------------------------------------------------------
-- 1. What the query does
--    Several result sets covering the common 'stuck pending' causes.
-- 2. Important columns
--    Various.
-- 3. How to interpret the output
--    Work top to bottom. The first CRITICAL finding is usually the cause.
-- 4. What indicates a problem
--    Requests Pending Normal while Standard shows free slots — look at specialization, hold, and requested_start_date.
-- 5. Recommended DBA action
--    Fix that cause. Do not restart managers as the first step if they are already running.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
PROMPT === 1. Core managers actual vs target ===
SELECT concurrent_queue_name, target_processes, running_processes, control_code, enabled_flag, target_node
FROM fnd_concurrent_queues_vl
WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM');

PROMPT === 2. Pending breakdown ===
SELECT status_code, COUNT(*) FROM fnd_concurrent_requests
WHERE phase_code='P' GROUP BY status_code;

PROMPT === 3. Held or future-dated ===
SELECT request_id, status_code, hold_flag, requested_start_date, concurrent_program_id
FROM fnd_concurrent_requests
WHERE phase_code='P'
AND (hold_flag='Y' OR requested_start_date > SYSDATE+1/1440)
ORDER BY requested_start_date
FETCH FIRST 40 ROWS ONLY;

PROMPT === 4. Run-alone blockers ===
SELECT r.request_id, p.user_concurrent_program_name, p.run_alone_flag, r.phase_code
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE r.phase_code='R' AND p.run_alone_flag='Y';

PROMPT
PROMPT === End of query: Diagnostic checklist ===
PROMPT

-- End of file
