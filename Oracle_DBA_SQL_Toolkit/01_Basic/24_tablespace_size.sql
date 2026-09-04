--------------------------------------------------------------------------------
-- File Name       : 24_tablespace_size.sql
-- Category        : 01_Basic
-- Purpose         : Show tablespace allocated, used, and free space with warning levels
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Daily capacity check. Warning bands:
--   < 70% used  = Normal
--   70-85%      = Monitor
--   85-95%      = Warning
--   > 95%       = Critical
-- Autoextend can hide 'full' until MAXSIZE is reached — see 04_Tablespaces_Datafiles.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Tablespace usage with alert bands
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins DBA_TABLESPACES, DBA_DATA_FILES, and DBA_FREE_SPACE for used percent.
-- 2. Important columns
--    TABLESPACE_NAME, ALLOC_GB, USED_GB, FREE_GB, USED_PCT, ALERT_LEVEL.
-- 3. How to interpret the output
--    USED_PCT is against current allocated size, not MAXSIZE. A 90% file that can autoextend is less urgent than a 90% file at MAXSIZE.
-- 4. What indicates a problem
--    CRITICAL (>95%) on SYSTEM, SYSAUX, UNDO, or a tablespace an EBS product needs tonight.
-- 5. Recommended DBA action
--    Add a datafile or raise MAXSIZE. Investigate unexpected growth before blindly adding space.
-- 6. Production cautions
--    Safe. Does not include TEMP — use 14_TEMP. Dictionary query; slight cost on huge databases.
-- 7. Required privileges
--    SELECT on DBA_TABLESPACES, DBA_DATA_FILES, DBA_FREE_SPACE
--------------------------------------------------------------------------------
WITH alloc AS (
       SELECT tablespace_name,
              SUM(bytes) AS alloc_bytes,
              SUM(DECODE(autoextensible, 'YES', maxbytes, bytes)) AS max_bytes
       FROM   dba_data_files
       GROUP BY tablespace_name
),
free AS (
       SELECT tablespace_name,
              SUM(bytes) AS free_bytes
       FROM   dba_free_space
       GROUP BY tablespace_name
)
SELECT
       ts.tablespace_name,
       ts.status,
       ts.contents,
       ROUND(a.alloc_bytes / 1024 / 1024 / 1024, 2) AS alloc_gb,
       ROUND((a.alloc_bytes - NVL(f.free_bytes, 0)) / 1024 / 1024 / 1024, 2) AS used_gb,
       ROUND(NVL(f.free_bytes, 0) / 1024 / 1024 / 1024, 2) AS free_gb,
       ROUND(a.max_bytes / 1024 / 1024 / 1024, 2) AS max_gb,
       ROUND((a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes, 1) AS used_pct,
       CASE
         WHEN (a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes > 95 THEN 'CRITICAL'
         WHEN (a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes > 85 THEN 'WARNING'
         WHEN (a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_tablespaces ts
JOIN   alloc a ON a.tablespace_name = ts.tablespace_name
LEFT JOIN free f ON f.tablespace_name = ts.tablespace_name
WHERE  ts.contents = 'PERMANENT'
ORDER BY used_pct DESC;

PROMPT
PROMPT === End of query: Tablespace usage with alert bands ===
PROMPT

-- End of file
