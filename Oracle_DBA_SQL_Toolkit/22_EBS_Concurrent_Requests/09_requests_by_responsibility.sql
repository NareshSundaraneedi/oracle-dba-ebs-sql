--------------------------------------------------------------------------------
-- File Name       : 09_requests_by_responsibility.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Requests by responsibility
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows which responsibility is generating load (GL Super User vs a custom XX).
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
-- QUERY 1: By responsibility
--------------------------------------------------------------------------------
-- 1. What the query does
--    Join FND_RESPONSIBILITY_TL.
-- 2. Important columns
--    RESPONSIBILITY_NAME, CNT, RUNNING.
-- 3. How to interpret the output
--    Month-end GL responsibility spikes are expected.
-- 4. What indicates a problem
--    A responsibility that should be inquiry-only submitting mass updates.
-- 5. Recommended DBA action
--    Request group / menu review (20/12).
-- 6. Production cautions
--    Safe. Last 24h.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT resp.responsibility_name, COUNT(*) requests,
       SUM(DECODE(r.phase_code,'R',1,0)) running,
       SUM(DECODE(r.phase_code,'P',1,0)) pending
FROM fnd_concurrent_requests r
JOIN fnd_responsibility_tl resp
       ON resp.responsibility_id = r.responsibility_id
      AND resp.language = USERENV('LANG')
WHERE r.request_date > SYSDATE-1
GROUP BY resp.responsibility_name
ORDER BY requests DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: By responsibility ===
PROMPT

-- End of file
