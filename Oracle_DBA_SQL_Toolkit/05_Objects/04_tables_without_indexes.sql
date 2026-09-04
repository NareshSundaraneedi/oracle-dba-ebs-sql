--------------------------------------------------------------------------------
-- File Name       : 04_tables_without_indexes.sql
-- Category        : 05_Objects
-- Purpose         : Find sizable tables that have no indexes at all
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- A table with no index is not always a problem (small setup tables,
-- interface staging). Large heap tables with no index often cause
-- full scans in EBS customizations.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Unindexed tables above a size threshold
--------------------------------------------------------------------------------
-- 1. What the query does
--    Anti-join DBA_TABLES to DBA_INDEXES and join size from DBA_SEGMENTS.
-- 2. Important columns
--    OWNER, TABLE_NAME, NUM_ROWS, SIZE_MB.
-- 3. How to interpret the output
--    NUM_ROWS stale if stats are old — check 07_Performance_Tuning stale stats.
-- 4. What indicates a problem
--    Custom XX table > 1GB with zero indexes and frequent queries.
-- 5. Recommended DBA action
--    Propose an index based on SQL, do not create blindly.
-- 6. Production cautions
--    Safe. Creating indexes is a change and is not done here.
-- 7. Required privileges
--    SELECT on DBA_TABLES, DBA_INDEXES, DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT
       t.owner,
       t.table_name,
       t.num_rows,
       t.last_analyzed,
       ROUND(s.bytes/1024/1024,1) AS size_mb
FROM   dba_tables t
JOIN   dba_segments s
       ON s.owner = t.owner AND s.segment_name = t.table_name AND s.segment_type LIKE 'TABLE%'
WHERE  t.temporary = 'N'
AND    t.secondary = 'N'
AND    t.nested    = 'NO'
AND    NOT EXISTS (
         SELECT 1 FROM dba_indexes i
         WHERE  i.table_owner = t.owner
         AND    i.table_name  = t.table_name
       )
AND    t.owner NOT IN ('SYS','SYSTEM','XDB')
AND    s.bytes > 64*1024*1024
ORDER BY s.bytes DESC;

PROMPT
PROMPT === End of query: Unindexed tables above a size threshold ===
PROMPT

-- End of file
