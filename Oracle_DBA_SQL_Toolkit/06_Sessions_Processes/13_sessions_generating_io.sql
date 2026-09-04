--------------------------------------------------------------------------------
-- File Name       : 13_sessions_generating_io.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Sessions with high physical reads/writes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Cumulative SESSTAT physical reads/writes. Good for finding a
-- session that has done a lot of I/O this life; not a rate. For rates
-- use AWR/ASH (licensed) or take two snapshots.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Physical I/O by session (cumulative)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Pivots key I/O statistics from GV$SESSTAT.
-- 2. Important columns
--    SID, PHY_READS, PHY_WRITES, SQL_ID.
-- 3. How to interpret the output
--    Long-lived APPS sessions accumulate I/O — sort by recent LAST_CALL_ET as well.
-- 4. What indicates a problem
--    A session with huge physical reads and a full-table-scan plan.
-- 5. Recommended DBA action
--    08_SQL_Tuning / 09 wait db file scattered read.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSTAT, GV_$STATNAME, GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.sql_id,
       s.last_call_et,
       MAX(CASE WHEN sn.name = 'physical reads' THEN st.value END) AS phy_reads,
       MAX(CASE WHEN sn.name = 'physical writes' THEN st.value END) AS phy_writes,
       MAX(CASE WHEN sn.name = 'physical read bytes' THEN ROUND(st.value/1024/1024) END) AS phy_read_mb
FROM   gv$session s
JOIN   gv$sesstat st ON st.inst_id = s.inst_id AND st.sid = s.sid
JOIN   gv$statname sn ON sn.inst_id = st.inst_id AND sn.statistic# = st.statistic#
WHERE  sn.name IN ('physical reads','physical writes','physical read bytes')
AND    s.type = 'USER'
GROUP BY s.inst_id, s.sid, s.serial#, s.username, s.sql_id, s.last_call_et
ORDER BY phy_reads DESC NULLS LAST
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Physical I/O by session (cumulative) ===
PROMPT

-- End of file
