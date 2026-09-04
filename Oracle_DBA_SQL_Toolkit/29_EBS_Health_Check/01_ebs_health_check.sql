--------------------------------------------------------------------------------
-- File Name       : 01_ebs_health_check.sql
-- Category        : 29_EBS_Health_Check
-- Purpose         : EBS + database health check with OK / WARNING / CRITICAL
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Single spool for shift handover or post-patch validation.
-- Each UNION ALL row is a check with alert_level OK, WARNING, or CRITICAL.
-- Review CRITICAL first, then WARNING. This script is read-only.
--
-- Checks: database/instance, tablespace/temp/undo, invalids, blocking, long SQL,
-- long/failed concurrent requests, managers, archive dest, FRA, sessions/processes,
-- EBS application invalids. ASM/Data Guard sections are included and report OK
-- if those views are empty (not configured).
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Health check result set
--------------------------------------------------------------------------------
-- 1. What the query does
--    A unified ALERT_LEVEL, CHECK_NAME, DETAIL query.
-- 2. Important columns
--    ALERT_LEVEL, CHECK_NAME, DETAIL.
-- 3. How to interpret the output
--    CRITICAL = act now. WARNING = plan today. OK = within thresholds (70/85/95 space, managers up).
-- 4. What indicates a problem
--    Any CRITICAL row.
-- 5. Recommended DBA action
--    Open the folder named in DETAIL. Do not fix blindly from this list.
-- 6. Production cautions
--    Safe but wide — may take 30-90 seconds on a large EBS DB. Do not run every minute.
-- 7. Required privileges
--    APPS + SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
COLUMN alert_level FORMAT A10
COLUMN check_name  FORMAT A32
COLUMN detail      FORMAT A80

SELECT alert_level, check_name, detail FROM (
SELECT CASE WHEN open_mode<>'READ WRITE' THEN 'CRITICAL' ELSE 'OK' END alert_level,
       'DATABASE_OPEN_MODE' check_name, open_mode||' '||database_role detail
FROM v$database
UNION ALL
SELECT CASE WHEN status<>'OPEN' THEN 'CRITICAL' ELSE 'OK' END, 'INSTANCE_STATUS', instance_name||' '||status
FROM v$instance
UNION ALL
SELECT CASE WHEN used_pct>95 THEN 'CRITICAL' WHEN used_pct>85 THEN 'WARNING' WHEN used_pct>70 THEN 'MONITOR' ELSE 'OK' END,
       'TABLESPACE '||tablespace_name, 'used_pct='||used_pct
FROM (
  SELECT ts.tablespace_name,
         ROUND((a.alloc-NVL(f.free,0))*100/NULLIF(a.alloc,0),1) used_pct
  FROM dba_tablespaces ts
  JOIN (SELECT tablespace_name, SUM(bytes) alloc FROM dba_data_files GROUP BY tablespace_name) a
        ON a.tablespace_name=ts.tablespace_name
  LEFT JOIN (SELECT tablespace_name, SUM(bytes) free FROM dba_free_space GROUP BY tablespace_name) f
        ON f.tablespace_name=ts.tablespace_name
  WHERE ts.contents='PERMANENT'
)
UNION ALL
SELECT CASE WHEN used_pct>95 THEN 'CRITICAL' WHEN used_pct>85 THEN 'WARNING' ELSE 'OK' END,
       'TEMP_USAGE', 'used_pct='||used_pct
FROM (
  SELECT ROUND((tablespace_size-free_space)*100/NULLIF(tablespace_size,0),1) used_pct
  FROM dba_temp_free_space WHERE ROWNUM=1
)
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'BLOCKING_SESSIONS',
       'blocker_waiters='||COUNT(*)
FROM gv$session WHERE blocking_session IS NOT NULL
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'LONG_SQL_15MIN',
       'active_over_15m='||COUNT(*)
FROM gv$session WHERE type='USER' AND status='ACTIVE' AND last_call_et>900
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'INVALID_APPS',
       'invalids='||COUNT(*)
FROM dba_objects WHERE status='INVALID' AND owner IN ('APPS','APPLSYS')
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'LONG_REQUESTS_2H',
       'running_over_2h='||COUNT(*)
FROM fnd_concurrent_requests WHERE phase_code='R' AND (SYSDATE-actual_start_date)*24>=2
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'FAILED_REQUESTS_24H',
       'errors='||COUNT(*)
FROM fnd_concurrent_requests WHERE phase_code='C' AND status_code='E' AND actual_completion_date>SYSDATE-1
UNION ALL
SELECT CASE WHEN running_processes=0 AND target_processes>0 THEN 'CRITICAL' ELSE 'OK' END,
       'MANAGER_'||concurrent_queue_name, 'target='||target_processes||' running='||running_processes
FROM fnd_concurrent_queues_vl
WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM')
UNION ALL
SELECT CASE WHEN error IS NOT NULL THEN 'CRITICAL' ELSE 'OK' END,
       'ARCHIVE_DEST_'||dest_id, NVL(error,'VALID')
FROM v$archive_dest WHERE status NOT IN ('INACTIVE') AND dest_id=1
UNION ALL
SELECT CASE WHEN space_used*100/NULLIF(space_limit,0)>95 THEN 'CRITICAL'
            WHEN space_used*100/NULLIF(space_limit,0)>85 THEN 'WARNING' ELSE 'OK' END,
       'FRA_USAGE', 'used_pct='||ROUND(space_used*100/NULLIF(space_limit,0),1)
FROM v$recovery_file_dest
UNION ALL
SELECT CASE WHEN REGEXP_LIKE(limit_value,'^[0-9]+$') AND current_utilization*100/TO_NUMBER(limit_value)>95 THEN 'CRITICAL'
            WHEN REGEXP_LIKE(limit_value,'^[0-9]+$') AND current_utilization*100/TO_NUMBER(limit_value)>85 THEN 'WARNING'
            WHEN REGEXP_LIKE(limit_value,'^[0-9]+$') AND current_utilization*100/TO_NUMBER(limit_value)>70 THEN 'MONITOR'
            ELSE 'OK' END,
       'RESOURCE_'||resource_name, 'current='||current_utilization||' limit='||limit_value
FROM v$resource_limit WHERE resource_name IN ('processes','sessions')
UNION ALL
SELECT CASE WHEN used_pct>95 THEN 'CRITICAL' WHEN used_pct>85 THEN 'WARNING' WHEN used_pct>70 THEN 'MONITOR' ELSE 'OK' END,
       'UNDO_USAGE', 'used_pct='||used_pct||' (ACTIVE+UNEXPIRED vs files)'
FROM (
  SELECT ROUND(NVL(u.used_bytes,0)*100/NULLIF(f.file_bytes,0),1) used_pct
  FROM (SELECT SUM(bytes) file_bytes FROM dba_data_files
        WHERE tablespace_name IN (SELECT tablespace_name FROM dba_tablespaces WHERE contents='UNDO')) f
  CROSS JOIN (SELECT SUM(bytes) used_bytes FROM dba_undo_extents WHERE status IN ('ACTIVE','UNEXPIRED')) u
)
UNION ALL
SELECT CASE WHEN NVL(usable_file_mb,0)=0 THEN 'OK'
            WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>95 THEN 'CRITICAL'
            WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>85 THEN 'WARNING'
            WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>70 THEN 'MONITOR'
            ELSE 'OK' END,
       'ASM_'||name, 'used_usable_pct='||ROUND((1-usable_file_mb/NULLIF(total_mb,0))*100,1)
FROM v$asm_diskgroup
UNION ALL
SELECT 'OK', 'ASM', 'not configured or not visible from this instance'
FROM dual WHERE NOT EXISTS (SELECT 1 FROM v$asm_diskgroup)
UNION ALL
SELECT CASE
         WHEN database_role='PRIMARY' THEN 'OK'
         WHEN database_role LIKE '%STANDBY%' THEN 'OK'
         ELSE 'WARNING'
       END,
       'DATAGUARD_ROLE', database_role||' protection='||protection_mode
FROM v$database
UNION ALL
SELECT CASE
         WHEN value IS NULL THEN 'OK'
         WHEN value LIKE '+00 00%' THEN 'OK'
         WHEN value LIKE '+00 01%' OR value LIKE '+00 02%' THEN 'WARNING'
         ELSE 'CRITICAL'
       END,
       'DATAGUARD_'||REPLACE(name,' ','_'), NVL(value,'n/a')
FROM v$dataguard_stats
WHERE name IN ('apply lag','transport lag')
UNION ALL
SELECT CASE WHEN value > (SELECT TO_NUMBER(value) FROM v$parameter WHERE name='cpu_count') THEN 'WARNING' ELSE 'OK' END,
       'HOST_LOAD', 'load='||value
FROM v$osstat WHERE stat_name='LOAD'
UNION ALL
SELECT 'OK', 'MEMORY_SGA_PGA',
       'sga_target='||(SELECT display_value FROM v$parameter WHERE name='sga_target')||
       ' pga_target='||(SELECT display_value FROM v$parameter WHERE name='pga_aggregate_target')
FROM dual
)
ORDER BY CASE alert_level WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END, check_name;

PROMPT
PROMPT === End of query: Health check result set ===
PROMPT

-- End of file
