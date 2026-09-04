--------------------------------------------------------------------------------
-- File Name       : 13_segment_growth.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Largest recent segment growth using DBA_HIST_SEG_STAT (AWR)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds objects that allocated the most space recently. Requires
-- Diagnostics Pack. Without the pack, use 14_largest_segments.sql as a point-in-time view.
--
-- LICENSING: DBA_HIST_SEG_STAT requires Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top segment space allocations in last 7 days
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sums SPACE_ALLOCATED_DELTA from DBA_HIST_SEG_STAT.
-- 2. Important columns
--    OWNER, OBJECT_NAME, SPACE_MB, LOGICAL_READS.
-- 3. How to interpret the output
--    High allocation on an interface or audit table is a purge candidate.
-- 4. What indicates a problem
--    A custom table growing without a retention policy.
-- 5. Recommended DBA action
--    Confirm with the application owner before truncate/purge. Generated only.
-- 6. Production cautions
--    AWR query — keep the window tight.
-- 7. Required privileges
--    SELECT on DBA_HIST_SEG_STAT, DBA_HIST_SNAPSHOT, DBA_OBJECTS
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT
       o.owner,
       o.object_name,
       o.object_type,
       ROUND(SUM(s.space_allocated_delta) / 1024 / 1024, 1) AS space_alloc_mb
FROM   dba_hist_seg_stat s
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = s.snap_id AND sn.dbid = s.dbid AND sn.instance_number = s.instance_number
JOIN   dba_objects o
       ON o.object_id = s.obj#
WHERE  sn.begin_interval_time > SYSDATE - 7
GROUP BY o.owner, o.object_name, o.object_type
HAVING SUM(s.space_allocated_delta) > 0
ORDER BY space_alloc_mb DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Top segment space allocations in last 7 days ===
PROMPT

-- End of file
