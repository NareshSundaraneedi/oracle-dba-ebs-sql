--------------------------------------------------------------------------------
-- File Name       : 13_average_runtime.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Average / p95 runtime per program (last 14 days, completed normal)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Baseline for 'is this run slow'. Uses successful completions only.
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
-- QUERY 1: Runtime stats
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates completed C/C requests.
-- 2. Important columns
--    PROGRAM, RUNS, AVG_MIN, P95_MIN, MAX_MIN.
-- 3. How to interpret the output
--    Compare a live run to AVG and P95, not MAX (MAX is often a one-off block).
-- 4. What indicates a problem
--    Live duration > 3x P95.
-- 5. Recommended DBA action
--    25 troubleshooting.
-- 6. Production cautions
--    Can be heavy on FND_CONCURRENT_REQUESTS — 14 day filter. Consider gathering stats on APPLSYS.FND_CONCURRENT_REQUESTS.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT p.user_concurrent_program_name,
       COUNT(*) runs,
       ROUND(AVG((r.actual_completion_date-r.actual_start_date)*24*60),1) avg_min,
       ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP
             (ORDER BY (r.actual_completion_date-r.actual_start_date)*24*60),1) p95_min,
       ROUND(MAX((r.actual_completion_date-r.actual_start_date)*24*60),1) max_min
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE r.phase_code='C' AND r.status_code='C'
AND r.actual_start_date > SYSDATE-14
AND r.actual_completion_date IS NOT NULL
GROUP BY p.user_concurrent_program_name
HAVING COUNT(*) >= 3
ORDER BY avg_min DESC
FETCH FIRST 60 ROWS ONLY;

PROMPT
PROMPT === End of query: Runtime stats ===
PROMPT

-- End of file
