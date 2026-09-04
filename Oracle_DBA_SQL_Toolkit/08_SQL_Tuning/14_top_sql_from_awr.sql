--------------------------------------------------------------------------------
-- File Name       : 14_top_sql_from_awr.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Top SQL from AWR by elapsed time for a time window
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 07_Performance_Tuning/01: V$SQL is cache-since-load;
-- this is bounded by snapshot times and is what you use after a spike.
--
-- LICENSING: Diagnostics Pack. This is the incident-window ranking — prefer this over V$SQL after the fact.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top AWR SQL by elapsed_delta
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sums DBA_HIST_SQLSTAT.elapsed_time_delta between two times.
-- 2. Important columns
--    SQL_ID, ELA_S, EXECS, GETS.
-- 3. How to interpret the output
--    Rank by ela_s for DB time. Also scan CPU and iowait columns.
-- 4. What indicates a problem
--    A new SQL_ID at the top vs last week's same-hour report.
-- 5. Recommended DBA action
--    Take SQL_ID to plan history and EBS module mapping.
-- 6. Production cautions
--    Pack licensed. Keep the window tight (hours, not months).
-- 7. Required privileges
--    SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT, DBA_HIST_SQLTEXT
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT
       st.sql_id,
       MIN(SUBSTR(t.sql_text,1,160)) AS sql_text,
       SUM(st.executions_delta) AS execs,
       ROUND(SUM(st.elapsed_time_delta)/1e6,1) AS ela_s,
       ROUND(SUM(st.cpu_time_delta)/1e6,1) AS cpu_s,
       SUM(st.buffer_gets_delta) AS gets,
       SUM(st.disk_reads_delta) AS reads,
       SUM(st.iowait_delta)/1e6 AS iowait_s
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
LEFT JOIN dba_hist_sqltext t
       ON t.sql_id = st.sql_id AND t.dbid = st.dbid
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
ORDER BY ela_s DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Top AWR SQL by elapsed_delta ===
PROMPT

-- End of file
