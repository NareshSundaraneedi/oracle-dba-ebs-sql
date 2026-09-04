--------------------------------------------------------------------------------
-- File Name       : 07_sql_high_elapsed.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : SQL with high elapsed per execution (long runners, not just popular)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Unlike 01 (cumulative elapsed), this ranks by elapsed/execution
-- so a once-per-day 4-hour job surfaces. Use when 'one request is stuck'.
--
-- Difference vs 01_top_sql_elapsed.sql: 01 finds DB-time hogs; this finds slow individual executions.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Highest elapsed per execution
--------------------------------------------------------------------------------
-- 1. What the query does
--    Orders GV$SQL by elapsed_time/executions with a minimum elapsed floor.
-- 2. Important columns
--    SQL_ID, ELA_PER_EXEC_S, EXECUTIONS.
-- 3. How to interpret the output
--    Single-execution SQL with hours of elapsed is a concurrent program candidate.
-- 4. What indicates a problem
--    ELA_PER_EXEC in thousands of seconds.
-- 5. Recommended DBA action
--    Join to EBS request (25_EBS) if MODULE looks like a concurrent program.
-- 6. Production cautions
--    Safe. Filter out SYS.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
SELECT
       sql_id,
       plan_hash_value,
       parsing_schema_name,
       module,
       executions,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,2) AS ela_per_exec_s,
       ROUND(cpu_time/NULLIF(executions,0)/1e6,2) AS cpu_per_exec_s,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    elapsed_time > 60*1e6
AND    parsing_schema_name NOT IN ('SYS','SYSTEM')
ORDER BY elapsed_time/executions DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Highest elapsed per execution ===
PROMPT

-- End of file
