--------------------------------------------------------------------------------
-- File Name       : 01_tablespace_usage.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Tablespace used percent with 70/85/95 alert bands including autoextend headroom
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Primary daily space dashboard. Reports used% of allocated size AND
-- used% of MAXSIZE so autoextend does not hide a real limit.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Tablespace usage vs allocated and vs maxsize
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes used/alloc and used/max for permanent tablespaces.
-- 2. Important columns
--    USED_PCT_ALLOC, USED_PCT_MAX, ALERT_LEVEL.
-- 3. How to interpret the output
--    <70 Normal, 70-85 Monitor, 85-95 Warning, >95 Critical — apply to USED_PCT_MAX for autoextend files.
-- 4. What indicates a problem
--    CRITICAL on SYSTEM, SYSAUX, UNDO, or an EBS product tablespace before a payroll/month-end run.
-- 5. Recommended DBA action
--    Add a datafile or raise MAXSIZE. Then find the growing segment (13_segment_growth.sql).
-- 6. Production cautions
--    Safe. Adding files is a change.
-- 7. Required privileges
--    SELECT on DBA_TABLESPACES, DBA_DATA_FILES, DBA_FREE_SPACE
--------------------------------------------------------------------------------
WITH alloc AS (
       SELECT tablespace_name,
              SUM(bytes) alloc_bytes,
              SUM(DECODE(autoextensible,'YES',maxbytes,bytes)) max_bytes
       FROM   dba_data_files
       GROUP BY tablespace_name
),
free AS (
       SELECT tablespace_name, SUM(bytes) free_bytes
       FROM   dba_free_space
       GROUP BY tablespace_name
)
SELECT
       ts.tablespace_name,
       ts.status,
       ROUND(a.alloc_bytes/1024/1024/1024,2) alloc_gb,
       ROUND((a.alloc_bytes-NVL(f.free_bytes,0))/1024/1024/1024,2) used_gb,
       ROUND(NVL(f.free_bytes,0)/1024/1024/1024,2) free_gb,
       ROUND(a.max_bytes/1024/1024/1024,2) max_gb,
       ROUND((a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.alloc_bytes,0),1) used_pct_alloc,
       ROUND((a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0),1) used_pct_max,
       CASE
         WHEN (a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0) > 95 THEN 'CRITICAL'
         WHEN (a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0) > 85 THEN 'WARNING'
         WHEN (a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_tablespaces ts
JOIN   alloc a ON a.tablespace_name = ts.tablespace_name
LEFT JOIN free f ON f.tablespace_name = ts.tablespace_name
WHERE  ts.contents = 'PERMANENT'
ORDER BY used_pct_max DESC;

PROMPT
PROMPT === End of query: Tablespace usage vs allocated and vs maxsize ===
PROMPT

-- End of file
