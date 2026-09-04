--------------------------------------------------------------------------------
-- File Name       : 10_restart_investigation.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Why managers die after start (logs, env, DB session)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: adcmctl start, processes appear, then vanish. Collect logfile_name, DB connect, library issues.
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
-- QUERY 1: Latest process logs and ICM status
--------------------------------------------------------------------------------
-- 1. What the query does
--    Latest process rows + ICM queue + APPS account status.
-- 2. Important columns
--    LOGFILE_NAME, PROCESS_STATUS, APPS STATUS.
-- 3. How to interpret the output
--    Read the manager logfile on the concurrent node (not the DB host unless shared).
-- 4. What indicates a problem
--    ORA-01017 in manager log after password change. or FNDLIBR not found.
-- 5. Recommended DBA action
--    AFPASSWD/FNDCPASS per MOS. Fix APPLPTMP/LD_LIBRARY_PATH. Do not reset APPS with ALTER USER.
-- 6. Production cautions
--    Safe to query. Password changes follow EBS documented utilities only.
-- 7. Required privileges
--    APPS + DBA_USERS
--------------------------------------------------------------------------------
SELECT q.user_concurrent_queue_name, p.process_status_code, p.process_start_date,
       p.logfile_name, p.manager_type, p.session_id
FROM fnd_concurrent_processes p
JOIN fnd_concurrent_queues_vl q ON q.concurrent_queue_id = p.concurrent_queue_id
WHERE p.process_start_date > SYSDATE - 1
ORDER BY p.process_start_date DESC
FETCH FIRST 50 ROWS ONLY;

SELECT username, account_status, expiry_date FROM dba_users
WHERE username IN ('APPS','APPLSYS');

SELECT user_concurrent_queue_name, target_processes, running_processes, control_code
FROM fnd_concurrent_queues_vl
WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM');

PROMPT
PROMPT === End of query: Latest process logs and ICM status ===
PROMPT

-- End of file
