--------------------------------------------------------------------------------
-- File Name       : 02_tablespace_free_space.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Show free space chunks (fragmentation-aware)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Total free space can look healthy while the largest free chunk is too
-- small for the next extent (especially dictionary-managed or huge
-- uniform extents).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Free space total vs largest chunk
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates DBA_FREE_SPACE per tablespace.
-- 2. Important columns
--    FREE_GB, LARGEST_CHUNK_MB, CHUNKS.
-- 3. How to interpret the output
--    Many tiny chunks + large next extent size = ORA-01653 / 01654 despite free space.
-- 4. What indicates a problem
--    LARGEST_CHUNK_MB smaller than the next extent of a growing table.
-- 5. Recommended DBA action
--    Coalesce is automatic for locally managed bitmap tablespaces. Add a datafile if the largest chunk is insufficient.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_FREE_SPACE
--------------------------------------------------------------------------------
SELECT
       tablespace_name,
       COUNT(*) AS free_chunks,
       ROUND(SUM(bytes)/1024/1024/1024,2) AS free_gb,
       ROUND(MAX(bytes)/1024/1024,1) AS largest_chunk_mb
FROM   dba_free_space
GROUP BY tablespace_name
ORDER BY largest_chunk_mb;

PROMPT
PROMPT === End of query: Free space total vs largest chunk ===
PROMPT

-- End of file
