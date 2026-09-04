--------------------------------------------------------------------------------
-- File Name       : 12_jobs_scheduler.sql
-- Category        : 02_Database_Administration
-- Purpose         : List DBMS_SCHEDULER jobs and DBMS_JOB leftovers
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Covers both DBMS_SCHEDULER (recommended) and legacy DBMS_JOB.
-- EBS concurrent processing is NOT listed here — see folder 21.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Scheduler jobs and running jobs
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_SCHEDULER_JOBS, DBA_SCHEDULER_RUNNING_JOBS, and DBA_JOBS.
-- 2. Important columns
--    JOB_NAME, ENABLED, STATE, LAST_START_DATE, NEXT_RUN_DATE, FAILURE_COUNT.
-- 3. How to interpret the output
--    STATE BROKEN or FAILURE_COUNT rising needs investigation. EBS Gather Stats may appear as a scheduler job.
-- 4. What indicates a problem
--    A custom job running heavy SQL during peak. Broken auto-stats job.
-- 5. Recommended DBA action
--    Disable with DBMS_SCHEDULER.DISABLE only after approval. Do not drop jobs from this script.
-- 6. Production cautions
--    Safe to query. Disabling jobs is a change.
-- 7. Required privileges
--    SELECT on DBA_SCHEDULER_JOBS, DBA_SCHEDULER_RUNNING_JOBS, DBA_JOBS
--------------------------------------------------------------------------------
SELECT
       owner,
       job_name,
       job_type,
       enabled,
       state,
       failure_count,
       last_start_date,
       next_run_date,
       run_count
FROM   dba_scheduler_jobs
WHERE  enabled = 'TRUE'
OR     state NOT IN ('SCHEDULED','DISABLED')
ORDER BY owner, job_name;

SELECT owner, job_name, session_id, running_instance, elapsed_time, cpu_used
FROM   dba_scheduler_running_jobs;

SELECT job, log_user, schema_user, broken, failures, next_date, interval, what
FROM   dba_jobs
ORDER BY job;

PROMPT
PROMPT === End of query: Scheduler jobs and running jobs ===
PROMPT

-- End of file
