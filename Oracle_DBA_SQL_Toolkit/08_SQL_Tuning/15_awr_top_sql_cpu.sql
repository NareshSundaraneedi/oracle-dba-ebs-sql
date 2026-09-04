--------------------------------------------------------------------------------
-- File Name       : 15_awr_top_sql_cpu.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Top AWR SQL by CPU for a time window
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Same windowing as 14 but ordered by cpu_time_delta.
--
-- LICENSING: Diagnostics Pack. Use when host CPU is the ticket, not elapsed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top AWR SQL by CPU
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sums CPU delta from DBA_HIST_SQLSTAT.
-- 2. Important columns
--    SQL_ID, CPU_S, ELA_S.
-- 3. How to interpret the output
--    CPU_S ≈ ELA_S → CPU bound. ELA >> CPU → wait bound (wrong script).
-- 4. What indicates a problem
--    CPU_S concentrated in one SQL_ID during the CPU spike.
-- 5. Recommended DBA action
--    Plan/cardinality work. Check PL/SQL functions in SELECT lists.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT
       st.sql_id,
       SUM(st.executions_delta) AS execs,
       ROUND(SUM(st.cpu_time_delta)/1e6,1) AS cpu_s,
       ROUND(SUM(st.elapsed_time_delta)/1e6,1) AS ela_s,
       SUM(st.buffer_gets_delta) AS gets
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
ORDER BY cpu_s DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Top AWR SQL by CPU ===
PROMPT

-- End of file
