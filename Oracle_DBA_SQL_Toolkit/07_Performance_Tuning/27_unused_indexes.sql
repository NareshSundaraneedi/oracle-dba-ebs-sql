--------------------------------------------------------------------------------
-- File Name       : 27_unused_indexes.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Indexes with no usage tracking hits (candidates only)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Left join DBA_INDEXES to DBA_INDEX_USAGE. Unused != droppable.
-- Unique, PK, and FK-supporting indexes stay.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Indexes without usage rows
--------------------------------------------------------------------------------
-- 1. What the query does
--    Finds non-unique indexes with no DBA_INDEX_USAGE row or zero access.
-- 2. Important columns
--    OWNER, INDEX_NAME, TABLE_NAME, SIZE_MB.
-- 3. How to interpret the output
--    Run this after a full month of tracking. Month-end indexes may look unused mid-month.
-- 4. What indicates a problem
--    Very large unused non-unique index on a hot table (DML tax).
-- 5. Recommended DBA action
--    Mark invisible first (19c) in a change window, then drop later. Generated only.
-- 6. Production cautions
--    WARNING: DROP/INVISIBLE generated only. Invisible indexes still require maintenance for DML.
-- 7. Required privileges
--    SELECT on DBA_INDEXES, DBA_INDEX_USAGE, DBA_SEGMENTS, DBA_CONSTRAINTS
--
-- Oracle 19c.
--------------------------------------------------------------------------------
SELECT
       i.owner,
       i.index_name,
       i.table_name,
       i.uniqueness,
       ROUND(s.bytes/1024/1024,1) AS size_mb,
       u.total_access_count,
       u.last_used
FROM   dba_indexes i
JOIN   dba_segments s
       ON s.owner = i.owner AND s.segment_name = i.index_name AND s.segment_type LIKE 'INDEX%'
LEFT JOIN dba_index_usage u
       ON u.owner = i.owner AND u.name = i.index_name
WHERE  i.owner NOT IN ('SYS','SYSTEM')
AND    i.uniqueness = 'NONUNIQUE'
AND    i.index_type = 'NORMAL'
AND    NVL(u.total_access_count,0) = 0
AND    s.bytes > 100*1024*1024
AND    NOT EXISTS (
         SELECT 1 FROM dba_constraints c
         WHERE  c.owner = i.table_owner
         AND    c.table_name = i.table_name
         AND    c.constraint_type IN ('P','U')
         AND    c.index_name = i.index_name
       )
ORDER BY s.bytes DESC
FETCH FIRST 40 ROWS ONLY;

-- WARNING: Review carefully before executing.
-- SELECT 'ALTER INDEX "'||owner||'"."'||index_name||'" INVISIBLE;' FROM ... ;

PROMPT
PROMPT === End of query: Indexes without usage rows ===
PROMPT

-- End of file
