--------------------------------------------------------------------------------
-- File Name       : 05_interface_processing_time.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Import program runtimes (ties interfaces to concurrent programs)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Uses FND_CONCURRENT_REQUESTS for the standard import program names.
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
-- QUERY 1: Import program durations
--------------------------------------------------------------------------------
-- 1. What the query does
--    Recent Autoinvoice, Payables Import, Journal Import, etc.
-- 2. Important columns
--    PROGRAM, MINUTES, STATUS.
-- 3. How to interpret the output
--    Runtime growing with pending count is expected; growing with flat volume is a tune issue.
-- 4. What indicates a problem
--    Autoinvoice 8 hours vs 40 minutes baseline.
-- 5. Recommended DBA action
--    25 SQL troubleshooting on that request_id.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT p.user_concurrent_program_name, r.request_id, r.status_code,
       r.actual_start_date,
       ROUND((NVL(r.actual_completion_date,SYSDATE)-r.actual_start_date)*24*60,1) minutes
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.user_concurrent_program_name IN (
      'Autoinvoice Import Program','Payables Open Interface Import',
      'Journal Import','Import Standard Purchase Orders',
      'Process transaction interface','Order Import')
OR p.concurrent_program_name IN ('RAXMTR','APXIIMPT','GLLEZL','POXPOPDOI','INCTIM','OEOIMP')
AND r.request_date > SYSDATE-7
ORDER BY r.actual_start_date DESC
FETCH FIRST 60 ROWS ONLY;

PROMPT
PROMPT === End of query: Import program durations ===
PROMPT

-- End of file
