--------------------------------------------------------------------------------
-- File Name       : 23_schema_size.sql
-- Category        : 01_Basic
-- Purpose         : Show segment size by schema owner
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Ranks schemas by space. On EBS, APPS is a synonym owner — most
-- space sits in product schemas (GL, AR, INV, XX custom, etc.).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Schema size ranking
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates DBA_SEGMENTS by owner.
-- 2. Important columns
--    OWNER, SEGMENT_COUNT, SIZE_GB.
-- 3. How to interpret the output
--    Sudden growth in one owner usually means a large interface table, audit table, or missing purge.
-- 4. What indicates a problem
--    A custom XX schema or FND/WF table growing faster than the daily baseline.
-- 5. Recommended DBA action
--    Drill into 05_Objects / EBS growth scripts for that owner. Do not resize tablespaces until you know which segment grew.
-- 6. Production cautions
--    Safe. DBA_SEGMENTS is a dictionary view; may take a few seconds on large EBS databases.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       owner,
       COUNT(*) AS segment_count,
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) AS size_gb
FROM   dba_segments
GROUP BY owner
ORDER BY SUM(bytes) DESC;

PROMPT
PROMPT === End of query: Schema size ranking ===
PROMPT

-- End of file
