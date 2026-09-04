--------------------------------------------------------------------------------
-- File Name       : 16_request_wait_analysis.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Wait events for running request sessions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Adds EVENT/WAIT_CLASS for running requests. Pack-free (V$SESSION).
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
-- QUERY 1: Request waits
--------------------------------------------------------------------------------
-- 1. What the query does
--    Running requests joined to GV$SESSION waits.
-- 2. Important columns
--    REQUEST_ID, EVENT, WAIT_CLASS, BLOCKING_SESSION.
-- 3. How to interpret the output
--    Application/Concurrency → locks (10). User I/O → SQL tune. Idle → waiting on apps tier or pipe.
-- 4. What indicates a problem
--    Many requests on enq: TX.
-- 5. Recommended DBA action
--    10_Locks + 25/07.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + GV$SESSION
--------------------------------------------------------------------------------
SELECT r.request_id, p.user_concurrent_program_name,
       s.event, s.wait_class, s.seconds_in_wait, s.blocking_session, s.sql_id
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN gv$session s ON s.sid = r.oracle_session_id
WHERE r.phase_code='R'
ORDER BY s.seconds_in_wait DESC NULLS LAST;

PROMPT
PROMPT === End of query: Request waits ===
PROMPT

-- End of file
