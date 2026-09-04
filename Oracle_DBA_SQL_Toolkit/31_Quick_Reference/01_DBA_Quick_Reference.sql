--------------------------------------------------------------------------------
-- File Name       : 01_DBA_Quick_Reference.sql
-- Category        : 31_Quick_Reference
-- Purpose         : Daily production DBA quick reference (pack-free)
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- The 15 queries a coverage DBA actually runs every morning. Not a substitute for the deep folders.
--
-- Pack-free daily checks. Use 08 AWR scripts only if licensed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Daily DBA pack
--------------------------------------------------------------------------------
-- 1. What the query does
--    Instance, space, sessions, blockers, FRA, archiver, invalids, resource limits.
-- 2. Important columns
--    Multiple result sets.
-- 3. How to interpret the output
--    Any CRITICAL-looking row → open the dedicated folder.
-- 4. What indicates a problem
--    See individual outputs.
-- 5. Recommended DBA action
--    Do not skip blockers and FRA.
-- 6. Production cautions
--    Safe. Keep it as a single spool for handover.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT instance_name, status, startup_time FROM gv$instance;
SELECT name, open_mode, database_role, log_mode FROM v$database;
SELECT tablespace_name, ROUND(used_percent,1) used_percent FROM (
  SELECT df.tablespace_name,
         (1-SUM(fs.bytes)/NULLIF(SUM(df.bytes),0))*100 used_percent
  FROM dba_data_files df LEFT JOIN dba_free_space fs ON fs.file_id=df.file_id
  GROUP BY df.tablespace_name) WHERE used_percent>70;
SELECT COUNT(*) blockers FROM gv$session WHERE blocking_session IS NOT NULL;
SELECT COUNT(*) active_users FROM gv$session WHERE type='USER' AND status='ACTIVE';
SELECT ROUND(space_used*100/NULLIF(space_limit,0),1) fra_used_pct FROM v$recovery_file_dest;
SELECT dest_id, status, error FROM v$archive_dest WHERE dest_id<=2;
SELECT resource_name, current_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT owner, COUNT(*) invalids FROM dba_objects WHERE status='INVALID' GROUP BY owner ORDER BY invalids DESC;
SELECT event, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND wait_class<>'Idle' GROUP BY event ORDER BY 2 DESC;

PROMPT
PROMPT === End of query: Daily DBA pack ===
PROMPT

-- End of file
