--------------------------------------------------------------------------------
-- File Name       : 09_failed_managers.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Managers that deactivated or have control codes other than Normal
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- CONTROL_CODE not N/null or enabled N unexpectedly.
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
-- QUERY 1: Unhealthy control codes
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters queues with deactivate/abort/terminate or enabled N but target>0 leftover.
-- 2. Important columns
--    CONTROL_CODE, ENABLED_FLAG.
-- 3. How to interpret the output
--    D=deactivate requested. Managers stay down until you Activate.
-- 4. What indicates a problem
--    Someone deactivated Standard during a clone and forgot.
-- 5. Recommended DBA action
--    Activate from Administer screen. Check who via audit if available.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT concurrent_queue_name, user_concurrent_queue_name, enabled_flag, control_code,
       target_processes, running_processes, target_node
FROM fnd_concurrent_queues_vl
WHERE NVL(control_code,'N') NOT IN ('N')
   OR (enabled_flag = 'N' AND concurrent_queue_name IN ('STANDARD','FNDICM','FNDCRM'))
ORDER BY concurrent_queue_name;

PROMPT
PROMPT === End of query: Unhealthy control codes ===
PROMPT

-- End of file
