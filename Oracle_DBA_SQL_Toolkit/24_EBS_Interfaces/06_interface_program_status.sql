--------------------------------------------------------------------------------
-- File Name       : 06_interface_program_status.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Is the import scheduled and succeeding?
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Last success per import program.
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
-- QUERY 1: Last import success
--------------------------------------------------------------------------------
-- 1. What the query does
--    Max successful completion per program.
-- 2. Important columns
--    PROGRAM, LAST_SUCCESS, LAST_STATUS.
-- 3. How to interpret the output
--    No success in 24h on a daily interface = incident.
-- 4. What indicates a problem
--    Last success days ago, pending rows > 0.
-- 5. Recommended DBA action
--    Submit the import after checking managers.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT p.user_concurrent_program_name,
       MAX(CASE WHEN r.status_code='C' THEN r.actual_completion_date END) last_success,
       MAX(r.actual_completion_date) last_any,
       MAX(r.status_code) KEEP (DENSE_RANK LAST ORDER BY r.request_id) last_status
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.concurrent_program_name IN ('RAXMTR','APXIIMPT','GLLEZL','POXPOPDOI','INCTIM','OEOIMP','PAXTRTRX')
AND r.request_date > SYSDATE-14
GROUP BY p.user_concurrent_program_name;

PROMPT
PROMPT === End of query: Last import success ===
PROMPT

-- End of file
