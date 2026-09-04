--------------------------------------------------------------------------------
-- File Name       : 11_internal_concurrent_manager.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Internal Concurrent Manager (ICM) health
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ICM (FNDICM) starts and monitors other managers. If ICM is down, nothing recovers.
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
-- QUERY 1: ICM queue and process
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters FNDICM.
-- 2. Important columns
--    RUNNING_PROCESSES, TARGET, CONTROL_CODE, OS_PID.
-- 3. How to interpret the output
--    ICM should have 1 process typically (plus Service Manager on 12.2).
-- 4. What indicates a problem
--    ICM RUNNING=0 — entire CP stack is unmanaged.
-- 5. Recommended DBA action
--    adcmctl.sh start apps/<pwd> on the concurrent node. Check FNDCPRT/ICM log.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT * FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name = 'FNDICM';

SELECT p.*
FROM fnd_concurrent_processes p
JOIN fnd_concurrent_queues q ON q.concurrent_queue_id = p.concurrent_queue_id
WHERE q.concurrent_queue_name = 'FNDICM'
AND p.process_start_date > SYSDATE - 3
ORDER BY p.process_start_date DESC;

PROMPT
PROMPT === End of query: ICM queue and process ===
PROMPT

-- End of file
