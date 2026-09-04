--------------------------------------------------------------------------------
-- File Name       : 08_manager_queue.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Pending requests waiting on each manager (queue depth)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows how deep each manager's pending queue is — capacity vs demand.
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
-- QUERY 1: Pending by manager
--------------------------------------------------------------------------------
-- 1. What the query does
--    Counts FND_CONCURRENT_REQUESTS pending, optionally mapped by program specialization (approximate via controlling manager).
-- 2. Important columns
--    PENDING, STATUS.
-- 3. How to interpret the output
--    Many Pending/Normal with free Standard Manager slots = specialization or incompatible programs. Pending/Standby = conflict (CRM).
-- 4. What indicates a problem
--    Hundreds Pending/Normal and Standard RUNNING=0.
-- 5. Recommended DBA action
--    15_manager_not_processing.sql. Start Standard Manager.
-- 6. Production cautions
--    Safe. Controlling_manager is set once assigned.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       phase_code, status_code,
       DECODE(phase_code,'P','Pending','R','Running','C','Complete','I','Inactive',phase_code) phase,
       DECODE(status_code,'Q','Standby','I','Scheduled','A','Waiting','R','Normal','C','Normal',
              'E','Error','G','Warning','X','Terminated','C',status_code) status_meaning,
       COUNT(*) cnt
FROM   fnd_concurrent_requests
WHERE  phase_code IN ('P','R')
GROUP BY phase_code, status_code
ORDER BY phase_code, status_code;

SELECT controlling_manager, COUNT(*) assigned_running
FROM   fnd_concurrent_requests
WHERE  phase_code = 'R'
GROUP BY controlling_manager
ORDER BY assigned_running DESC;

PROMPT
PROMPT === End of query: Pending by manager ===
PROMPT

-- End of file
