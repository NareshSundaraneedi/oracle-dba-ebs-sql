--------------------------------------------------------------------------------
-- File Name       : 20_check_concurrent_manager_impact.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 20 — is this request blocking the managers?
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Same program count running, Standard Manager slots, pending behind it (run_alone). Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Step 20 — is this request blocking the managers?
--------------------------------------------------------------------------------
-- 1. What the query does
--    Same program count running, Standard Manager slots, pending behind it (run_alone).
-- 2. Important columns
--    See SELECT list.
-- 3. How to interpret the output
--    Capture the output into the incident ticket before changing anything.
-- 4. What indicates a problem
--    Missing session or SQL_ID means the program is not in a DB call — check the request log.
-- 5. Recommended DBA action
--    Continue the next numbered script. Do not skip to kill.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
DEFINE request_id = 0
SELECT p.run_alone_flag, p.user_concurrent_program_name,
       q.user_concurrent_queue_name, q.target_processes, q.running_processes
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
LEFT JOIN fnd_concurrent_queues_vl q ON q.concurrent_queue_id=r.controlling_manager
WHERE r.request_id=&request_id;

SELECT COUNT(*) other_running_same_program
FROM fnd_concurrent_requests r2
JOIN fnd_concurrent_requests r1 ON r1.concurrent_program_id=r2.concurrent_program_id
WHERE r1.request_id=&request_id AND r2.phase_code='R' AND r2.request_id<>&request_id;

PROMPT
PROMPT === End of query: Step 20 — is this request blocking the managers? ===
PROMPT

-- End of file
