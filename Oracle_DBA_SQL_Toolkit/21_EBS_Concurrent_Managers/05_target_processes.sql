--------------------------------------------------------------------------------
-- File Name       : 05_target_processes.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Target processes vs work shifts (capacity plan)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- TARGET_PROCESSES is the current shift's target. Overnight shifts may drop to 0 — looks like 'manager down'.
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
-- QUERY 1: Targets
--------------------------------------------------------------------------------
-- 1. What the query does
--    Queues with target and max.
-- 2. Important columns
--    TARGET_PROCESSES, MAX_PROCESSES, SLEEP_SECONDS.
-- 3. How to interpret the output
--    MAX is the ceiling. TARGET is what ICM tries to keep alive now.
-- 4. What indicates a problem
--    TARGET 0 during the day because the work shift ended.
-- 5. Recommended DBA action
--    07_work_shifts.sql. Fix the shift, do not just raise max.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT user_concurrent_queue_name, target_node, target_processes, max_processes,
       sleep_seconds, enabled_flag, control_code
FROM fnd_concurrent_queues_vl
ORDER BY target_processes DESC;

PROMPT
PROMPT === End of query: Targets ===
PROMPT

-- End of file
