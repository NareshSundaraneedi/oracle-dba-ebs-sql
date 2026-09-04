--------------------------------------------------------------------------------
-- File Name       : 04_manager_processes.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : All concurrent process rows including inactive
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- History of manager processes (A/K/S). Use to see crash loops.
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
-- QUERY 1: Process history
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_CONCURRENT_PROCESSES last 7 days.
-- 2. Important columns
--    QUEUE, STATUS, START, OS_PID.
-- 3. How to interpret the output
--    Many short-lived A→K cycles = manager dying on startup (env, library, DB connect).
-- 4. What indicates a problem
--    ICM restarting Standard Manager every minute.
-- 5. Recommended DBA action
--    Manager log in $APPLCSF/$APPLLOG. See 10.
-- 6. Production cautions
--    Safe. Table can be large — date filter.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       q.user_concurrent_queue_name,
       p.process_status_code,
       p.process_start_date,
       p.process_end_date,
       p.os_process_id,
       p.session_id,
       p.logfile_name
FROM   fnd_concurrent_processes p
JOIN   fnd_concurrent_queues_vl q
       ON q.concurrent_queue_id = p.concurrent_queue_id
WHERE  p.process_start_date > SYSDATE - 7
ORDER BY p.process_start_date DESC
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Process history ===
PROMPT

-- End of file
