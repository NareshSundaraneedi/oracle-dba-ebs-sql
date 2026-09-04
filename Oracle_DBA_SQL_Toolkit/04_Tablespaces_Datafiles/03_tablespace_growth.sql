--------------------------------------------------------------------------------
-- File Name       : 03_tablespace_growth.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Estimate tablespace growth from AWR or DBA_HIST_TBSPC_SPACE_USAGE
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Uses AWR history when licensed. Without Diagnostics Pack, use the
-- current size query in 01 and compare to last week's export of this output.
--
-- LICENSING: DBA_HIST_* requires Oracle Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Tablespace growth over the last 14 days (AWR)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_HIST_TBSPC_SPACE_USAGE joined to tablespace names.
-- 2. Important columns
--    TABLESPACE_NAME, DAYS, GROWTH_GB, DAILY_MB.
-- 3. How to interpret the output
--    Positive daily growth is normal. A step change means a load, index rebuild, or missing purge.
-- 4. What indicates a problem
--    APPS_TS_TX_DATA growing tens of GB/day.
-- 5. Recommended DBA action
--    Identify the segment (13/14). Schedule purge or add space before the weekend job.
-- 6. Production cautions
--    Do not run against a large AWR retention without the time filter. Pack licensed.
-- 7. Required privileges
--    SELECT on DBA_HIST_TBSPC_SPACE_USAGE, DBA_HIST_SNAPSHOT, DBA_TABLESPACES
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT
       ts.tablespace_name,
       ROUND(MAX(su.tablespace_size * ts.block_size) / 1024 / 1024 / 1024, 2) AS end_alloc_gb,
       ROUND(MIN(su.tablespace_size * ts.block_size) / 1024 / 1024 / 1024, 2) AS start_alloc_gb,
       ROUND( (MAX(su.tablespace_usedsize * ts.block_size) - MIN(su.tablespace_usedsize * ts.block_size))
              / 1024 / 1024 / 1024, 2) AS used_growth_gb
FROM   dba_hist_tbspc_space_usage su
JOIN   v$tablespace vt ON vt.ts# = su.tablespace_id
JOIN   dba_tablespaces ts ON ts.tablespace_name = vt.name
JOIN   dba_hist_snapshot sn ON sn.snap_id = su.snap_id AND sn.dbid = su.dbid AND sn.instance_number = su.instance_number
WHERE  sn.begin_interval_time > SYSDATE - 14
GROUP BY ts.tablespace_name
ORDER BY used_growth_gb DESC NULLS LAST;

PROMPT
PROMPT === End of query: Tablespace growth over the last 14 days (AWR) ===
PROMPT

-- End of file
