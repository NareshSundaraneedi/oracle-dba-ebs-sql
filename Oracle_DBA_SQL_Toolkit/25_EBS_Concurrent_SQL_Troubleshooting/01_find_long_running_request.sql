--------------------------------------------------------------------------------
-- File Name       : 01_find_long_running_request.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 1 — find the long-running concurrent request
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Identify REQUEST_ID, program, user, start time, oracle_session_id. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 1 — find the long-running concurrent request
--------------------------------------------------------------------------------
-- 1. What the query does
--    Identify REQUEST_ID, program, user, start time, oracle_session_id.
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
DEFINE hours = 1
SELECT r.request_id, p.user_concurrent_program_name, u.user_name,
       r.actual_start_date, ROUND((SYSDATE-r.actual_start_date)*24,2) hours_running,
       r.oracle_session_id, r.oracle_process_id, r.parent_request_id, r.argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='R' AND (SYSDATE-r.actual_start_date)*24 >= &hours
ORDER BY r.actual_start_date;

PROMPT
PROMPT === End of query: Step 1 — find the long-running concurrent request ===
PROMPT

-- End of file
