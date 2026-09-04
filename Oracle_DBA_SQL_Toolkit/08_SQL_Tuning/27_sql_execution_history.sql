--------------------------------------------------------------------------------
-- File Name       : 27_sql_execution_history.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Historical executions from SQL Monitor and AWR for one SQL_ID
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Combines last executions (monitor) with AWR per-snap stats.
--
-- LICENSING: V$SQL_MONITOR / DBA_HIST_REPORTS SQL Monitor is Tuning Pack. DBA_HIST_SQLSTAT is Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Execution history for &sql_id
--------------------------------------------------------------------------------
-- 1. What the query does
--    SQL Monitor rows plus AWR deltas.
-- 2. Important columns
--    SQL_EXEC_START, STATUS, ELAPSED_S, SNAP ELA.
-- 3. How to interpret the output
--    Look for a step change in elapsed at a snap boundary (stats, volume, plan).
-- 4. What indicates a problem
--    Last successful run 10 min, current 3 hours.
-- 5. Recommended DBA action
--    Compare plans and binds between those times.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on GV_$SQL_MONITOR, DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT
--
-- Tuning Pack (monitor) and Diagnostics Pack (AWR).
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs

SELECT sql_exec_start, status, inst_id, sid,
       ROUND(elapsed_time/1e6,1) elapsed_s,
       ROUND(cpu_time/1e6,1) cpu_s,
       buffer_gets, disk_reads
FROM   gv$sql_monitor
WHERE  sql_id = '&sql_id'
ORDER BY sql_exec_start DESC;

SELECT TO_CHAR(sn.begin_interval_time,'DD-MON HH24:MI') snap_time,
       st.plan_hash_value,
       st.executions_delta execs,
       ROUND(st.elapsed_time_delta/NULLIF(st.executions_delta,0)/1e6,3) ela_per_exec_s
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  st.sql_id = '&sql_id'
AND    sn.begin_interval_time > SYSDATE - 7
ORDER BY sn.begin_interval_time;

PROMPT
PROMPT === End of query: Execution history for &sql_id ===
PROMPT

-- End of file
