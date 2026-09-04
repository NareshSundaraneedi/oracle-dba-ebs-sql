--------------------------------------------------------------------------------
-- File Name       : 05_top_sql_executions.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Top SQL by execution count
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Ranks cursors in GV$SQL by executions. This is since the cursor
-- was loaded (not a wall-clock rate). Use AWR (08 / AWR scripts) for
-- a time-bounded ranking. Difference vs similar scripts: this file is
-- strictly ordered by executions so you do not mix units.
--
-- LICENSING: V$SQL is included with Enterprise Edition. DBA_HIST_* and ASH require Diagnostics Pack. SQL Tuning Advisor / SQL Monitor historical require Tuning Pack / Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top SQL by executions
--------------------------------------------------------------------------------
-- 1. What the query does
--    Selects from GV$SQL ordered by executions.
-- 2. Important columns
--    SQL_ID, EXECUTIONS, ELA_PER_EXEC_S, PLAN_HASH_VALUE, MODULE, SQL_TEXT.
-- 3. How to interpret the output
--    High executions with tiny ela/exec can still dominate DB time (EBS chatty Forms SQL). High executions with high ela/exec is worse.
-- 4. What indicates a problem
--    A SQL executed millions of times from a loop that should be set-based.
-- 5. Recommended DBA action
--    Fix the application loop or add a bulk API. SQL tuning alone may not be enough.
-- 6. Production cautions
--    Safe. GV$SQL can be large; FETCH FIRST limits cost. Do not flush the shared pool.
-- 7. Required privileges
--    SELECT on GV_$SQL
--
-- Does not require Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT
       sql_id,
       plan_hash_value,
       inst_id,
       child_number,
       parsing_schema_name,
       module,
       executions,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       ROUND(cpu_time/1e6,1) AS cpu_s,
       buffer_gets,
       disk_reads,
       rows_processed,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s,
       ROUND(buffer_gets/NULLIF(executions,0)) AS gets_per_exec,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    parsing_schema_name NOT IN ('SYS','SYSTEM')
ORDER BY executions DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Top SQL by executions ===
PROMPT

-- End of file
