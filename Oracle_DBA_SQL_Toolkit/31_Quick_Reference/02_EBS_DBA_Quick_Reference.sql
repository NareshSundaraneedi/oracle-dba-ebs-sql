--------------------------------------------------------------------------------
-- File Name       : 02_EBS_DBA_Quick_Reference.sql
-- Category        : 31_Quick_Reference
-- Purpose         : Daily EBS DBA quick reference
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Managers, running/pending/failed requests, APPS invalids, APPS sessions, WF deferred.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Daily EBS pack
--------------------------------------------------------------------------------
-- 1. What the query does
--    Core EBS operational queries.
-- 2. Important columns
--    Multiple result sets.
-- 3. How to interpret the output
--    ICM/Standard/CRM must be up. Failed requests need logs.
-- 4. What indicates a problem
--    CRITICAL managers or APPS invalids.
-- 5. Recommended DBA action
--    Folders 21-25.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT concurrent_queue_name, target_processes, running_processes, control_code
FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM');
SELECT phase_code, status_code, COUNT(*) FROM fnd_concurrent_requests
WHERE request_date>SYSDATE-1 GROUP BY phase_code, status_code;
SELECT r.request_id, p.user_concurrent_program_name, ROUND((SYSDATE-r.actual_start_date)*24,2) hrs
FROM fnd_concurrent_requests r JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
WHERE r.phase_code='R' AND (SYSDATE-r.actual_start_date)*24>=1;
SELECT COUNT(*) apps_invalids FROM dba_objects WHERE status='INVALID' AND owner IN ('APPS','APPLSYS');
SELECT COUNT(*) apps_active FROM gv$session WHERE username='APPS' AND status='ACTIVE';
SELECT activity_status, COUNT(*) FROM wf_item_activity_statuses WHERE activity_status IN ('DEFERRED','ERROR') GROUP BY activity_status;

PROMPT
PROMPT === End of query: Daily EBS pack ===
PROMPT

-- End of file
