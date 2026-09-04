--------------------------------------------------------------------------------
-- File Name       : 17_awr_top_sql_io.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Top AWR SQL by I/O wait and disk reads
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Orders by iowait_delta and disk_reads_delta.
--
-- LICENSING: Diagnostics Pack. Use when storage latency or throughput is the ticket.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AWR I/O heavy SQL
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sums iowait and disk_reads from DBA_HIST_SQLSTAT.
-- 2. Important columns
--    SQL_ID, IOWAIT_S, READS.
-- 3. How to interpret the output
--    High reads with low iowait = fast storage or cached. High iowait with modest reads = latency.
-- 4. What indicates a problem
--    One SQL saturating the I/O subsystem.
-- 5. Recommended DBA action
--    09 I/O waits + plan FTS/index range.
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
       ROUND(SUM(st.iowait_delta)/1e6,1) AS iowait_s,
       SUM(st.disk_reads_delta) AS reads,
       SUM(st.physical_read_bytes_delta)/1024/1024 AS read_mb
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
ORDER BY iowait_s DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: AWR I/O heavy SQL ===
PROMPT

-- End of file
