--------------------------------------------------------------------------------
-- File Name       : 05_unusable_indexes.sql
-- Category        : 05_Objects
-- Purpose         : List UNUSABLE indexes and partitions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- UNUSABLE indexes appear after partition maintenance, failed rebuilds,
-- or SKIP_UNUSABLE_INDEXES workloads. Queries may error or skip the index.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Unusable indexes
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_INDEXES and DBA_IND_PARTITIONS for STATUS UNUSABLE.
-- 2. Important columns
--    OWNER, INDEX_NAME, STATUS, PARTITION_NAME.
-- 3. How to interpret the output
--    A global index UNUSABLE after DROP PARTITION is expected until rebuilt.
-- 4. What indicates a problem
--    Unique constraint index UNUSABLE — DML will fail.
-- 5. Recommended DBA action
--    ALTER INDEX REBUILD is a change. Generated only. Use ONLINE if available and approved.
-- 6. Production cautions
--    WARNING: REBUILD generated only. Rebuilds generate redo and can be long.
-- 7. Required privileges
--    SELECT on DBA_INDEXES, DBA_IND_PARTITIONS
--------------------------------------------------------------------------------
SELECT owner, index_name, table_name, status, tablespace_name
FROM   dba_indexes
WHERE  status = 'UNUSABLE'
ORDER BY owner, index_name;

SELECT index_owner, index_name, partition_name, status
FROM   dba_ind_partitions
WHERE  status = 'UNUSABLE'
ORDER BY index_owner, index_name, partition_name;

-- WARNING: Review carefully before executing.
SELECT 'ALTER INDEX "'||owner||'"."'||index_name||'" REBUILD;' AS rebuild_cmd
FROM   dba_indexes
WHERE  status = 'UNUSABLE'
AND    partitioned = 'NO';

PROMPT
PROMPT === End of query: Unusable indexes ===
PROMPT

-- End of file
