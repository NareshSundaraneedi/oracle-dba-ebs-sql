--------------------------------------------------------------------------------
-- File Name       : 06_workflow_background_processes.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : Workflow Background Process concurrent requests
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- The engine that moves DEFERRED/TIMEOUT activities. If it is not scheduled, workflows stall.
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
-- QUERY 1: Background program requests
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_CONCURRENT_REQUESTS for FNDWFBG / Workflow Background Process.
-- 2. Important columns
--    REQUEST_ID, PHASE, STATUS, ARGUMENTS, NEXT.
-- 3. How to interpret the output
--    Should be scheduled frequently (often every few minutes per item type, site-specific).
-- 4. What indicates a problem
--    No successful run today and DEFERRED is high.
-- 5. Recommended DBA action
--    Submit/schedule Workflow Background Process. Do not start multiple conflicting ones without a plan.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT r.request_id, r.phase_code, r.status_code, r.requested_start_date,
       r.actual_start_date, r.actual_completion_date, r.argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.concurrent_program_name = 'FNDWFBG'
   OR p.user_concurrent_program_name LIKE 'Workflow Background%'
ORDER BY r.request_id DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Background program requests ===
PROMPT

-- End of file
