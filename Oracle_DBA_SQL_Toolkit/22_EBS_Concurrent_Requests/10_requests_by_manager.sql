--------------------------------------------------------------------------------
-- File Name       : 10_requests_by_manager.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Running requests grouped by controlling manager
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Which manager is busy. Complements 21/08.
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
-- QUERY 1: By controlling manager
--------------------------------------------------------------------------------
-- 1. What the query does
--    Join controlling_manager to queues.
-- 2. Important columns
--    QUEUE, REQUESTS, AVG_MINUTES.
-- 3. How to interpret the output
--    One specialized manager at max while Standard is idle — expected if specialized.
-- 4. What indicates a problem
--    All load on Standard because specialization never assigned.
-- 5. Recommended DBA action
--    21/03 specialization.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT q.user_concurrent_queue_name, COUNT(*) running_requests,
       ROUND(AVG((SYSDATE-r.actual_start_date)*24*60),1) avg_minutes
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_queues_vl q ON q.concurrent_queue_id = r.controlling_manager
WHERE r.phase_code='R'
GROUP BY q.user_concurrent_queue_name
ORDER BY running_requests DESC;

PROMPT
PROMPT === End of query: By controlling manager ===
PROMPT

-- End of file
