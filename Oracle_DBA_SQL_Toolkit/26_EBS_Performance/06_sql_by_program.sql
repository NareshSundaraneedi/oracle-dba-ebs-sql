--------------------------------------------------------------------------------
-- File Name       : 06_sql_by_program.sql
-- Category        : 26_EBS_Performance
-- Purpose         : SQL for sessions whose MODULE matches a concurrent program name
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Matches running program names to SQL cache.
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
-- QUERY 1: SQL for a program name
--------------------------------------------------------------------------------
-- 1. What the query does
--    Join running requests' program name to gv$sql.module.
-- 2. Important columns
--    PROGRAM, SQL_ID.
-- 3. How to interpret the output
--    MODULE may be the short concurrent_program_name.
-- 4. What indicates a problem
--    Program SQL not matching a known good plan_hash.
-- 5. Recommended DBA action
--    25/15.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE program_name = %Create Accounting%
SELECT DISTINCT p.user_concurrent_program_name, s.sql_id, s.event, s.sid
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
JOIN gv$session s ON s.sid=r.oracle_session_id
WHERE r.phase_code='R' AND p.user_concurrent_program_name LIKE '&program_name';

PROMPT
PROMPT === End of query: SQL for a program name ===
PROMPT

-- End of file
