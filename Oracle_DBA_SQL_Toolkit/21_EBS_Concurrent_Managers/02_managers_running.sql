--------------------------------------------------------------------------------
-- File Name       : 02_managers_running.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Managers that currently have OS/DB processes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 01: this lists only queues with RUNNING_PROCESSES > 0 and their live process rows.
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
-- QUERY 1: Running managers and processes
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins queues to FND_CONCURRENT_PROCESSES with process_status_code A (active).
-- 2. Important columns
--    QUEUE, OS_PROCESS_ID, SESSION_ID, PROCESS_STATUS_CODE, PROCESS_START_DATE.
-- 3. How to interpret the output
--    A=active, K=killed, S=deactivated. Oracle SESSION_ID maps to GV$SESSION.SID on that node.
-- 4. What indicates a problem
--    Queue shows running_processes>0 but no active process rows — stale counts after a crash.
-- 5. Recommended DBA action
--    Relink/restart via adcmctl after checking ICM. See 10_restart_investigation.sql.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       q.user_concurrent_queue_name,
       q.target_node,
       p.os_process_id,
       p.oracle_process_id,
       p.session_id,
       p.process_status_code,
       p.process_start_date,
       p.manager_type
FROM   fnd_concurrent_queues_vl q
JOIN   fnd_concurrent_processes p
       ON p.concurrent_queue_id = q.concurrent_queue_id
      AND p.queue_application_id = q.application_id
WHERE  p.process_status_code = 'A'
ORDER BY q.user_concurrent_queue_name, p.process_start_date;

PROMPT
PROMPT === End of query: Running managers and processes ===
PROMPT

-- End of file
