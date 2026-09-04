--------------------------------------------------------------------------------
-- File Name       : 04_sql_tuning_advisor.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : How to invoke SQL Tuning Advisor (commands generated, not auto-run)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SQL Tuning Advisor can recommend indexes, profiles, and stats.
-- It is a change-control activity. This file only shows the API.
--
-- LICENSING: Tuning Pack required. Do not run advisor on production peak without a window — it executes test queries.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Advisor API (commented — do not auto-execute)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Prints DBMS_SQLTUNE usage as comments.
-- 2. Important columns
--    N/A
-- 3. How to interpret the output
--    A profile is a safer first accept than a new index.
-- 4. What indicates a problem
--    Advisor hung because the SQL is extremely expensive — use time limits.
-- 5. Recommended DBA action
--    Create a tuning task in a window. Review before ACCEPT_SQL_PROFILE.
-- 6. Production cautions
--    WARNING: Advisor executes SQL. Tuning Pack. Not auto-run.
-- 7. Required privileges
--    ADVISOR privilege. Tuning Pack.
--
-- Requires Tuning Pack.
--------------------------------------------------------------------------------
PROMPT SQL Tuning Advisor requires Tuning Pack and ADVISOR privilege.
PROMPT Example (run manually in a change window):

/*
DECLARE
  l_task VARCHAR2(64);
BEGIN
  l_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(
              sql_id   => '0w6u2qj2zn5hs',
              scope    => 'COMPREHENSIVE',
              time_limit => 300,
              task_name  => 'TUNED_0w6u2qj2zn5hs');
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK(task_name => 'TUNED_0w6u2qj2zn5hs');
END;
/

SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('TUNED_0w6u2qj2zn5hs') FROM dual;

-- WARNING: ACCEPT_SQL_PROFILE changes optimizer behavior.
-- EXEC DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name => 'TUNED_0w6u2qj2zn5hs', name => 'PROF_0w6u2qj2zn5hs');
*/

SELECT task_name, status, execution_start
FROM   dba_advisor_tasks
WHERE  advisor_name = 'SQL Tuning Advisor'
ORDER BY execution_start DESC NULLS LAST
FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: Advisor API (commented — do not auto-execute) ===
PROMPT

-- End of file
