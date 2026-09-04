--------------------------------------------------------------------------------
-- File Name       : 16_largest_indexes.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Largest indexes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Index segments that dominate space or cause rebuild windows to be long.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top 40 indexes
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_SEGMENTS to INDEX%.
-- 2. Important columns
--    OWNER, SEGMENT_NAME, SIZE_GB.
-- 3. How to interpret the output
--    A bloated index after a mass delete may be a rebuild candidate — rebuild is a change and locks (online rebuild still has constraints).
-- 4. What indicates a problem
--    Index larger than its table after heavy deletes.
-- 5. Recommended DBA action
--    Confirm with DBA_INDEXES and clustering factor. Rebuild only with a plan.
-- 6. Production cautions
--    Safe to query. ALTER INDEX REBUILD is not generated as auto-run.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT
       owner,
       segment_name,
       partition_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb
FROM   dba_segments
WHERE  segment_type LIKE 'INDEX%'
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Top 40 indexes ===
PROMPT

-- End of file
