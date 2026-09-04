--------------------------------------------------------------------------------
-- File Name       : 17_concurrent_request_performance.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : One program: last runs vs baseline (duration + status)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE program_name. The chart you paste into a ticket.
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
-- QUERY 1: Performance series
--------------------------------------------------------------------------------
-- 1. What the query does
--    Last 30 completions for one program with duration.
-- 2. Important columns
--    REQUEST_ID, MINUTES, STATUS, START.
-- 3. How to interpret the output
--    Look for a cliff after a date (stats, volume, patch).
-- 4. What indicates a problem
--    Cliff without a volume change — plan/stats.
-- 5. Recommended DBA action
--    25/15 and 17.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE program_name = %Create Accounting%

SELECT r.request_id, r.status_code,
       TO_CHAR(r.actual_start_date,'DD-MON HH24:MI') started,
       ROUND((r.actual_completion_date-r.actual_start_date)*24*60,1) minutes,
       SUBSTR(r.argument_text,1,80) args
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.user_concurrent_program_name LIKE '&program_name'
AND r.phase_code='C'
AND r.actual_start_date > SYSDATE-30
ORDER BY r.actual_start_date;

PROMPT
PROMPT === End of query: Performance series ===
PROMPT

-- End of file
