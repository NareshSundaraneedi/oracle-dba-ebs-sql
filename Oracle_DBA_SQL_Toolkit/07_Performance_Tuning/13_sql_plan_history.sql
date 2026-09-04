--------------------------------------------------------------------------------
-- File Name       : 13_sql_plan_history.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Plan history for one SQL_ID from AWR (DBA_HIST_SQLSTAT)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Time series of PLAN_HASH_VALUE and elapsed/exec for a known SQL_ID.
-- Use after a user says 'it got slow yesterday'.
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
-- QUERY 1: AWR plan history for &sql_id
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_HIST_SQLSTAT joined to snapshots.
-- 2. Important columns
--    SNAP_TIME, PLAN_HASH_VALUE, ELA_PER_EXEC, EXECS.
-- 3. How to interpret the output
--    A new PLAN_HASH_VALUE coinciding with a runtime jump is a regression.
-- 4. What indicates a problem
--    Plan flip after autostats or a bind change.
-- 5. Recommended DBA action
--    08_SQL_Tuning baselines / profiles. Restore stats only with a plan.
-- 6. Production cautions
--    Pack licensed. Bind the SQL_ID.
-- 7. Required privileges
--    SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs

SELECT
       TO_CHAR(sn.begin_interval_time, 'DD-MON HH24:MI') AS snap_time,
       st.instance_number,
       st.plan_hash_value,
       st.executions_delta AS execs,
       ROUND(st.elapsed_time_delta/NULLIF(st.executions_delta,0)/1e6,4) AS ela_per_exec_s,
       ROUND(st.buffer_gets_delta/NULLIF(st.executions_delta,0)) AS gets_per_exec,
       ROUND(st.disk_reads_delta/NULLIF(st.executions_delta,0)) AS reads_per_exec
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  st.sql_id = '&sql_id'
AND    sn.begin_interval_time > SYSDATE - 14
ORDER BY sn.begin_interval_time, st.instance_number;

PROMPT
PROMPT === End of query: AWR plan history for &sql_id ===
PROMPT

-- End of file
