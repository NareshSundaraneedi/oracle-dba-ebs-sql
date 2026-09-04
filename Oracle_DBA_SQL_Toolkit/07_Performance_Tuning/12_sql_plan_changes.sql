--------------------------------------------------------------------------------
-- File Name       : 12_sql_plan_changes.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : SQL_IDs that currently have more than one plan hash in cache
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Multiple PLAN_HASH_VALUE for one SQL_ID in GV$SQL means the
-- optimizer produced different plans (adaptive, binds, stats, degree).
-- This is a current-cache view. Historical regressions need AWR (14).
--
-- Difference vs 14_sql_plan_regressions.sql: this is cache-only and pack-free; 14 uses AWR.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL with multiple plans in cache
--------------------------------------------------------------------------------
-- 1. What the query does
--    Groups GV$SQL by SQL_ID having COUNT(DISTINCT plan_hash_value) > 1.
-- 2. Important columns
--    SQL_ID, PLAN_COUNT, PLANS.
-- 3. How to interpret the output
--    Different plans can be OK (adaptive). Compare elapsed/exec per plan_hash.
-- 4. What indicates a problem
--    One plan_hash is 100x slower and still being used.
-- 5. Recommended DBA action
--    Consider a SQL baseline (Tuning Pack / EE) after proving the good plan. See 08_SQL_Tuning.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
SELECT
       sql_id,
       COUNT(DISTINCT plan_hash_value) AS plan_count,
       COUNT(*) AS child_cursors,
       ROUND(SUM(elapsed_time)/1e6,1) AS elapsed_s
FROM   gv$sql
GROUP BY sql_id
HAVING COUNT(DISTINCT plan_hash_value) > 1
ORDER BY child_cursors DESC
FETCH FIRST 40 ROWS ONLY;

SELECT sql_id, plan_hash_value, inst_id, child_number,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s,
       buffer_gets
FROM   gv$sql
WHERE  sql_id = '&sql_id'
ORDER BY ela_per_exec_s DESC NULLS LAST;

PROMPT
PROMPT === End of query: SQL with multiple plans in cache ===
PROMPT

-- End of file
