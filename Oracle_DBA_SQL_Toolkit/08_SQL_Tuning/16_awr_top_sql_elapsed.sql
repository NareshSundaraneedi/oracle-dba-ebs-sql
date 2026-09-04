--------------------------------------------------------------------------------
-- File Name       : 16_awr_top_sql_elapsed.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Alias-style elapsed ranking with per-exec (AWR)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- 14 ranks total DB time. This also shows per-exec so a 1-exec
-- 4-hour job is not hidden below a chatty SQL.
--
-- LICENSING: Diagnostics Pack. Difference vs 14: includes ela/exec so long-runners with few execs are visible.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AWR elapsed with per-exec
--------------------------------------------------------------------------------
-- 1. What the query does
--    Same source as 14 with ela/exec computed.
-- 2. Important columns
--    SQL_ID, ELA_S, ELA_PER_EXEC_S.
-- 3. How to interpret the output
--    Use total ela_s for instance impact; ela_per_exec for user pain.
-- 4. What indicates a problem
--    Low execs, huge ela_per_exec — concurrent program.
-- 5. Recommended DBA action
--    Folder 25 EBS SQL troubleshooting.
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
       ROUND(SUM(st.elapsed_time_delta)/1e6,1) AS ela_s,
       ROUND(SUM(st.elapsed_time_delta)/NULLIF(SUM(st.executions_delta),0)/1e6,3) AS ela_per_exec_s
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
HAVING SUM(st.executions_delta) > 0
ORDER BY ela_per_exec_s DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: AWR elapsed with per-exec ===
PROMPT

-- End of file
