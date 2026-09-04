--------------------------------------------------------------------------------
-- File Name       : 03_completed_requests.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Recently completed requests
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- PHASE C last N hours. Use for 'did it finish?'
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
-- QUERY 1: Completed recently
--------------------------------------------------------------------------------
-- 1. What the query does
--    PHASE_CODE C with DEFINE hours.
-- 2. Important columns
--    REQUEST_ID, STATUS, ACTUAL_COMPLETION_DATE, ARGUMENT_TEXT.
-- 3. How to interpret the output
--    Status C normal, G warning, E error, X terminated.
-- 4. What indicates a problem
--    N/A — inventory.
-- 5. Recommended DBA action
--    Drill into 04 if E/X.
-- 6. Production cautions
--    Safe. Table is huge — always filter time.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE hours = 8

SELECT r.request_id, r.status_code, p.user_concurrent_program_name, u.user_name,
       r.actual_start_date, r.actual_completion_date,
       ROUND((r.actual_completion_date-r.actual_start_date)*24*60,1) minutes,
       SUBSTR(r.argument_text,1,80) argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='C'
AND r.actual_completion_date > SYSDATE - &hours/24
ORDER BY r.actual_completion_date DESC
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Completed recently ===
PROMPT

-- End of file
