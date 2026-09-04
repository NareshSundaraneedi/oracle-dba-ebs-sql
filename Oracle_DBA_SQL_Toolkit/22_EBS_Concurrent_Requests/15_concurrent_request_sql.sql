--------------------------------------------------------------------------------
-- File Name       : 15_concurrent_request_sql.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Map a request to SQL_ID via session / module
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Uses ORACLE_SESSION_ID and MODULE. MODULE is often the concurrent program name. Difference vs 25/02-03: this is the request-folder shortcut.
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
-- QUERY 1: Request to SQL
--------------------------------------------------------------------------------
-- 1. What the query does
--    Join running requests to GV$SESSION.
-- 2. Important columns
--    REQUEST_ID, SID, SQL_ID, EVENT.
-- 3. How to interpret the output
--    If ORACLE_SESSION_ID is null, match on MODULE and USERNAME APPS plus program.
-- 4. What indicates a problem
--    No session — the program is between DB calls or on the apps tier (host/reports).
-- 5. Recommended DBA action
--    Check the request log. Host programs may not have a DB session the whole time.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT r.request_id, p.user_concurrent_program_name,
       r.oracle_session_id, s.inst_id, s.sid, s.serial#, s.sql_id, s.event, s.last_call_et
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
LEFT JOIN gv$session s ON s.sid = r.oracle_session_id AND s.username = 'APPS'
WHERE r.phase_code='R'
ORDER BY r.actual_start_date;

PROMPT
PROMPT === End of query: Request to SQL ===
PROMPT

-- End of file
