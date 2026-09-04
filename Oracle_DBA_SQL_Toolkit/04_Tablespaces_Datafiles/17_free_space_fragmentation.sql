--------------------------------------------------------------------------------
-- File Name       : 17_free_space_fragmentation.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Detect free space fragmentation that can block extents
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Compares number of free extents and largest chunk to tablespace
-- next-extent characteristics.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Fragmentation indicators
--------------------------------------------------------------------------------
-- 1. What the query does
--    Free chunk histogram per tablespace.
-- 2. Important columns
--    CHUNKS, AVG_CHUNK_MB, MAX_CHUNK_MB.
-- 3. How to interpret the output
--    LMT AUTOALLOCATE rarely needs coalesce. Dictionary-managed or huge UNIFORM sizes do.
-- 4. What indicates a problem
--    UNIFORM 256MB and max free chunk 128MB — next extent fails.
-- 5. Recommended DBA action
--    Add a datafile. Avoid exporting/importing just to defragment LMT.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_FREE_SPACE, DBA_TABLESPACES
--------------------------------------------------------------------------------
SELECT
       f.tablespace_name,
       t.extent_management,
       t.allocation_type,
       COUNT(*) AS free_chunks,
       ROUND(AVG(f.bytes)/1024/1024,1) AS avg_chunk_mb,
       ROUND(MAX(f.bytes)/1024/1024,1) AS max_chunk_mb,
       ROUND(SUM(f.bytes)/1024/1024/1024,2) AS free_gb
FROM   dba_free_space f
JOIN   dba_tablespaces t ON t.tablespace_name = f.tablespace_name
GROUP BY f.tablespace_name, t.extent_management, t.allocation_type
ORDER BY free_chunks DESC;

PROMPT
PROMPT === End of query: Fragmentation indicators ===
PROMPT

-- End of file
