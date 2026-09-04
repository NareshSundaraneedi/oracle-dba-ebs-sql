--------------------------------------------------------------------------------
-- File Name       : 30_optimizer_statistics.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Optimizer-related parameters and stats job status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows optimizer parameters and autostats job state. EBS often
-- disables default autostats in favor of FND_STATS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Optimizer parameters and auto stats job
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$PARAMETER optimizer% plus DBA_AUTOTASK_CLIENT.
-- 2. Important columns
--    NAME, VALUE, CLIENT_NAME, STATUS.
-- 3. How to interpret the output
--    optimizer_dynamic_sampling, optimizer_index_cost_adj (legacy EBS settings), and adaptive features affect plans.
-- 4. What indicates a problem
--    Autostats running on a large EBS schema during peak contrary to site standard.
-- 5. Recommended DBA action
--    Align with the EBS MOS notes for your release. Do not flip adaptive features mid-incident.
-- 6. Production cautions
--    Safe. Changing optimizer parameters is a major change.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, DBA_AUTOTASK_CLIENT, DBA_AUTOTASK_JOB_HISTORY
-- EBS relevance  : Critical for EBS
--------------------------------------------------------------------------------
SELECT name, display_value, isdefault
FROM   v$parameter
WHERE  name LIKE 'optimizer%'
OR     name IN ('statistics_level','cursor_sharing','query_rewrite_enabled')
ORDER BY name;

SELECT client_name, status, consumer_group, window_group
FROM   dba_autotask_client;

SELECT client_name, job_name, job_status, job_start_time, job_duration
FROM   dba_autotask_job_history
WHERE  job_start_time > SYSDATE - 7
ORDER BY job_start_time DESC;

PROMPT
PROMPT === End of query: Optimizer parameters and auto stats job ===
PROMPT

-- End of file
