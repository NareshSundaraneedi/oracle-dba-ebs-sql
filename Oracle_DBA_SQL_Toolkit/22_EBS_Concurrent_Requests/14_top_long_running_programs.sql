--------------------------------------------------------------------------------
-- File Name       : 14_top_long_running_programs.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Programs that consumed the most concurrent runtime last 7 days
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Capacity view: which programs eat the managers. Difference vs 13: ranked by SUM(duration), not average.
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
-- QUERY 1: Top consumers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sum of run minutes by program.
-- 2. Important columns
--    PROGRAM, TOTAL_HOURS, RUNS.
-- 3. How to interpret the output
--    Gather stats, Create Accounting, and custom interfaces often dominate.
-- 4. What indicates a problem
--    A custom XX program in the top 3 unexpectedly.
-- 5. Recommended DBA action
--    26 EBS performance + 25.
-- 6. Production cautions
--    Safe with date filter.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT p.user_concurrent_program_name,
       COUNT(*) runs,
       ROUND(SUM((NVL(r.actual_completion_date,SYSDATE)-r.actual_start_date)*24),1) total_hours
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE r.actual_start_date > SYSDATE-7
AND r.phase_code IN ('R','C')
GROUP BY p.user_concurrent_program_name
ORDER BY total_hours DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Top consumers ===
PROMPT

-- End of file
