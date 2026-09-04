--------------------------------------------------------------------------------
-- File Name       : 01_concurrent_manager_status.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Concurrent manager target vs actual processes and enabled flag
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- First check when 'nothing is running'. Compares TARGET_PROCESSES to RUNNING_PROCESSES.
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
-- QUERY 1: Queue status
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads FND_CONCURRENT_QUEUES_VL for enabled managers and process counts.
-- 2. Important columns
--    USER_CONCURRENT_QUEUE_NAME, TARGET_NODE, TARGET_PROCESSES, RUNNING_PROCESSES, ENABLED_FLAG, CONTROL_CODE.
-- 3. How to interpret the output
--    RUNNING < TARGET means the manager is down or still coming up. CONTROL_CODE N=normal, D=deactivate, A=abort, T=terminate, P=suspended.
-- 4. What indicates a problem
--    Standard Manager TARGET>0 but RUNNING=0 during business hours.
-- 5. Recommended DBA action
--    Check ICM (11), admin scripts, and FND_CONCURRENT_PROCESSES. Do not UPDATE control_code by SQL; use Concurrent > Manager > Administer.
-- 6. Production cautions
--    Safe. Restarting managers is an apps-tier action (adcmctl).
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       concurrent_queue_name,
       user_concurrent_queue_name,
       target_node,
       enabled_flag,
       control_code,
       target_processes,
       running_processes,
       max_processes,
       cache_size
FROM   fnd_concurrent_queues_vl
ORDER BY running_processes DESC, target_processes DESC, user_concurrent_queue_name;

PROMPT
PROMPT === End of query: Queue status ===
PROMPT

-- End of file
