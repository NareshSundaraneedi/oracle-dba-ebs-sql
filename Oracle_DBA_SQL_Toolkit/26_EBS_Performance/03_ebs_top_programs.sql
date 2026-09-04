--------------------------------------------------------------------------------
-- File Name       : 03_ebs_top_programs.sql
-- Category        : 26_EBS_Performance
-- Purpose         : Top concurrent programs by DB-side load (running now)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Running requests joined to session elapsed.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Running programs with session time
--------------------------------------------------------------------------------
-- 1. What the query does
--    Requests phase R + last_call_et.
-- 2. Important columns
--    PROGRAM, REQUEST_ID, LAST_CALL_ET.
-- 3. How to interpret the output
--    last_call_et is the current SQL call, not total request time.
-- 4. What indicates a problem
--    A program with last_call_et of hours.
-- 5. Recommended DBA action
--    25 master.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT p.user_concurrent_program_name, r.request_id, s.last_call_et, s.sql_id, s.event
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
LEFT JOIN gv$session s ON s.sid=r.oracle_session_id
WHERE r.phase_code='R' ORDER BY s.last_call_et DESC NULLS LAST;

PROMPT
PROMPT === End of query: Running programs with session time ===
PROMPT

-- End of file
