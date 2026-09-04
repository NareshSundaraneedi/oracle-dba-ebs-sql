--------------------------------------------------------------------------------
-- File Name       : 03_Performance_Troubleshooting_Quick_Reference.sql
-- Category        : 31_Quick_Reference
-- Purpose         : Performance incident first five minutes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Order: CPU vs wait → top wait → blockers → top SQL → EBS running requests. Then dive into folders 07-10 or 25.
--
-- If the last query fails you are not on an EBS database — skip it.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Perf first five
--------------------------------------------------------------------------------
-- 1. What the query does
--    Time model, waits, blockers, top SQL, long requests.
-- 2. Important columns
--    Multiple.
-- 3. How to interpret the output
--    If blockers>0 stop and do locks. Else if CPU% high do CPU SQL. Else do the #1 wait event script.
-- 4. What indicates a problem
--    Incident in progress.
-- 5. Recommended DBA action
--    Do not flush shared pool. Do not bounce. Do not gather schema stats mid-incident.
-- 6. Production cautions
--    Safe. AWR not included (license).
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT ROUND(cpu.value*100/NULLIF(dbt.value,0),1) cpu_pct_of_dbtime
FROM v$sys_time_model dbt, v$sys_time_model cpu
WHERE dbt.stat_name='DB time' AND cpu.stat_name='DB CPU';
SELECT event, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND wait_class<>'Idle' GROUP BY event ORDER BY 2 DESC;
SELECT COUNT(*) blockers FROM gv$session WHERE blocking_session IS NOT NULL;
SELECT sql_id, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,100) t FROM v$sql WHERE parsing_schema_name NOT IN ('SYS','SYSTEM') ORDER BY elapsed_time DESC FETCH FIRST 10 ROWS ONLY;
SELECT request_id, ROUND((SYSDATE-actual_start_date)*24*60,1) mins FROM fnd_concurrent_requests WHERE phase_code='R' ORDER BY actual_start_date;

PROMPT
PROMPT === End of query: Perf first five ===
PROMPT

-- End of file
