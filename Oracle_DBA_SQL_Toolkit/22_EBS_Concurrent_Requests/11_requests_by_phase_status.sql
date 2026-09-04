--------------------------------------------------------------------------------
-- File Name       : 11_requests_by_phase_status.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Phase/status histogram (current workload picture)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Single snapshot for the bridge: how many R/P/C today.
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
-- QUERY 1: Histogram
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group by phase_code, status_code for recent requests.
-- 2. Important columns
--    PHASE, STATUS, CNT.
-- 3. How to interpret the output
--    A wall of P/R is a manager problem. A wall of C/E is a functional/data problem.
-- 4. What indicates a problem
--    Pending >> Running and managers have free slots.
-- 5. Recommended DBA action
--    21/15.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT phase_code, status_code, COUNT(*) cnt
FROM fnd_concurrent_requests
WHERE request_date > SYSDATE-1
GROUP BY phase_code, status_code
ORDER BY phase_code, status_code;

PROMPT
PROMPT === End of query: Histogram ===
PROMPT

-- End of file
