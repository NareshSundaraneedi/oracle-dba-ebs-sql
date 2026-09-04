--------------------------------------------------------------------------------
-- File Name       : 14_sql_plan_regressions.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Detect SQL_IDs whose elapsed/exec worsened across plans in AWR
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Compares average elapsed/exec per plan_hash over a recent window
-- and flags SQL with a wide gap between best and worst plan.
--
-- LICENSING: Diagnostics Pack required.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Plan performance spread last 7 days
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates DBA_HIST_SQLSTAT by SQL_ID and PLAN_HASH_VALUE.
-- 2. Important columns
--    SQL_ID, PLAN_HASH, ELA_PER_EXEC, EXECS.
-- 3. How to interpret the output
--    A plan with few execs and huge ela can be an outlier bind.
-- 4. What indicates a problem
--    Worst plan 10x+ the best plan with material execution counts.
-- 5. Recommended DBA action
--    Pin the good plan (baseline) after validation.
-- 6. Production cautions
--    Pack licensed. Can be heavy — 7 day window.
-- 7. Required privileges
--    SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
WITH p AS (
       SELECT
              st.sql_id,
              st.plan_hash_value,
              SUM(st.executions_delta) execs,
              SUM(st.elapsed_time_delta)/1e6 ela_s
       FROM   dba_hist_sqlstat st
       JOIN   dba_hist_snapshot sn
              ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
       WHERE  sn.begin_interval_time > SYSDATE - 7
       GROUP BY st.sql_id, st.plan_hash_value
       HAVING SUM(st.executions_delta) > 0
)
SELECT
       sql_id,
       COUNT(*) AS plans,
       ROUND(MIN(ela_s/execs),4) AS best_ela_exec_s,
       ROUND(MAX(ela_s/execs),4) AS worst_ela_exec_s,
       ROUND(MAX(ela_s/execs)/NULLIF(MIN(ela_s/execs),0),1) AS regression_factor,
       SUM(execs) AS total_execs
FROM   p
GROUP BY sql_id
HAVING COUNT(*) > 1
AND    MAX(ela_s/execs) > MIN(ela_s/execs) * 5
ORDER BY regression_factor DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Plan performance spread last 7 days ===
PROMPT

-- End of file
