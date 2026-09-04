--------------------------------------------------------------------------------
-- File Name       : 06_actual_processes.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Actual vs target with alert bands
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- RUNNING=0 and TARGET>0 is CRITICAL for ICM/Standard/CRM.
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
-- QUERY 1: Actual vs target alerts
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes a simple alert for under-process queues.
-- 2. Important columns
--    TARGET, RUNNING, ALERT.
-- 3. How to interpret the output
--    OK if running>=target or target=0. WARNING if running < target. CRITICAL if running=0 and target>0 for core managers.
-- 4. What indicates a problem
--    CRITICAL on STANDARD or INTERNAL.
-- 5. Recommended DBA action
--    Start managers. Check ICM first.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       concurrent_queue_name,
       user_concurrent_queue_name,
       target_processes,
       running_processes,
       CASE
         WHEN target_processes > 0 AND running_processes = 0
              AND concurrent_queue_name IN ('STANDARD','FNDICM','FNDCRM') THEN 'CRITICAL'
         WHEN target_processes > 0 AND running_processes < target_processes THEN 'WARNING'
         ELSE 'OK'
       END AS alert_level
FROM   fnd_concurrent_queues_vl
WHERE  enabled_flag = 'Y'
ORDER BY CASE alert_level WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
         user_concurrent_queue_name;

PROMPT
PROMPT === End of query: Actual vs target alerts ===
PROMPT

-- End of file
