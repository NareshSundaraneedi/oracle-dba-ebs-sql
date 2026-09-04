--------------------------------------------------------------------------------
-- File Name       : 03_io_suddenly_high.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : I/O suddenly high
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: storage latency/IOPS alerts, scattered/sequential reads #1. Initial: I/O wait events avg_ms, top physical SQL, TEMP spills, RMAN running. Evidence: storage array stats, ASH iowait if licensed. Causes: FTS, index rebuild, RMAN, checkpoint, interconnect misread as disk. Fix: reschedule heavy jobs, tune SQL, check RMAN channels. Post-fix: User I/O avg_ms and IOPS back to baseline.
--
-- Production playbook.  reschedule heavy jobs, tune SQL, check RMAN channels.
-- Post-fix: User I/O avg_ms and IOPS back to baseline.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: I/O suddenly high — queries
--------------------------------------------------------------------------------
-- 1. What the query does
--    Playbook queries for this symptom.
-- 2. Important columns
--    See SELECT list / PROMPT for evidence to collect.
-- 3. How to interpret the output
--    Work Symptom → Initial checks → these SQL → Evidence → Root cause → Fix → Post-fix as in the file header DESCRIPTION.
-- 4. What indicates a problem
--    Matches the symptom in the file name.
-- 5. Recommended DBA action
--    See DESCRIPTION recommended fix. No destructive SQL is auto-run.
-- 6. Production cautions
--    Safe to query. Bounces, kills, and parameter changes are out of band.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT event, ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms, total_waits
FROM v$system_event WHERE wait_class IN ('User I/O','System I/O') ORDER BY time_waited_micro DESC FETCH FIRST 15 ROWS ONLY;
SELECT sql_id, disk_reads, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,120) t
FROM v$sql WHERE disk_reads>10000 ORDER BY disk_reads DESC FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT === End of query: I/O suddenly high — queries ===
PROMPT

-- End of file
