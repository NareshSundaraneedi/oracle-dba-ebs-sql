--------------------------------------------------------------------------------
-- File Name       : 07_requests_by_program.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Request history for one program name
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE program_name. Used for 'is this program always slow or just today'.
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
-- QUERY 1: By program
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filter user_concurrent_program_name or concurrent_program_name.
-- 2. Important columns
--    REQUEST_ID, STATUS, MINUTES, START.
-- 3. How to interpret the output
--    A step change in duration after a patch/stats is a plan regression.
-- 4. What indicates a problem
--    Last 5 runs 10x slower.
-- 5. Recommended DBA action
--    25/15 plan changes + 17 stats.
-- 6. Production cautions
--    Safe. Last 14 days.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE program_name = %Gather Schema%

SELECT r.request_id, r.phase_code, r.status_code, u.user_name,
       r.actual_start_date, r.actual_completion_date,
       ROUND((NVL(r.actual_completion_date,SYSDATE)-r.actual_start_date)*24*60,1) minutes,
       SUBSTR(r.argument_text,1,100) argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE (p.user_concurrent_program_name LIKE '&program_name'
    OR p.concurrent_program_name LIKE '&program_name')
AND r.request_date > SYSDATE-14
ORDER BY r.request_id DESC
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: By program ===
PROMPT

-- End of file
