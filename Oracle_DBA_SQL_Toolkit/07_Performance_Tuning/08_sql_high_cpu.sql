--------------------------------------------------------------------------------
-- File Name       : 08_sql_high_cpu.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : SQL with high CPU per execution
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Per-execution CPU. Complements 02 (cumulative CPU).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Highest CPU per execution
--------------------------------------------------------------------------------
-- 1. What the query does
--    Orders GV$SQL by cpu_time/executions.
-- 2. Important columns
--    SQL_ID, CPU_PER_EXEC_S.
-- 3. How to interpret the output
--    High CPU/exec with low disk reads = CPU-bound plan (functions, misestimate).
-- 4. What indicates a problem
--    CPU/exec jumped after a stats gather (plan change).
-- 5. Recommended DBA action
--    Compare plans (13/14).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
SELECT
       sql_id,
       plan_hash_value,
       module,
       executions,
       ROUND(cpu_time/NULLIF(executions,0)/1e6,2) AS cpu_per_exec_s,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,2) AS ela_per_exec_s,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    cpu_time > 10*1e6
ORDER BY cpu_time/executions DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Highest CPU per execution ===
PROMPT

-- End of file
