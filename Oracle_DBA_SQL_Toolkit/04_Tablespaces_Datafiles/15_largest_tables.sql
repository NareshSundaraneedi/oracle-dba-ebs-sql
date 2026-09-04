--------------------------------------------------------------------------------
-- File Name       : 15_largest_tables.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Largest tables (excludes indexes and undo)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- TABLE and TABLE PARTITION segments only. Pair with 16 for indexes.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top 40 tables
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_SEGMENTS to TABLE%.
-- 2. Important columns
--    OWNER, SEGMENT_NAME, SIZE_GB, TABLESPACE_NAME.
-- 3. How to interpret the output
--    Compare table size to corresponding index size — indexes larger than the table can be a design smell or bitmap/function indexes.
-- 4. What indicates a problem
--    Interface table in the top 10.
-- 5. Recommended DBA action
--    Archive/purge with functional approval.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT
       owner,
       segment_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb
FROM   dba_segments
WHERE  segment_type LIKE 'TABLE%'
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Top 40 tables ===
PROMPT

-- End of file
