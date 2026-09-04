--------------------------------------------------------------------------------
-- File Name       : 29_stale_statistics.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Objects marked stale in DBA_TAB_STATISTICS
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- STALE_STATS = YES means monitoring thinks enough DML occurred.
-- Stale is a hint, not a command to gather now.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Stale table statistics
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_TAB_STATISTICS where STALE_STATS = YES.
-- 2. Important columns
--    OWNER, TABLE_NAME, STALE_STATS, LAST_ANALYZED, NUM_ROWS.
-- 3. How to interpret the output
--    A table can be stale and still have a good plan. Gathering can make things worse if it invalidates a stable plan.
-- 4. What indicates a problem
--    Critical table stale after a huge data load and plans are clearly wrong (cardinality off by orders of magnitude).
-- 5. Recommended DBA action
--    Gather for that table in a window with the EBS-approved method. Avoid GATHER_SCHEMA_STATS cascade mid-day.
-- 6. Production cautions
--    Safe to query. DBMS_STATS is a change and is not executed.
-- 7. Required privileges
--    SELECT on DBA_TAB_STATISTICS
--------------------------------------------------------------------------------
SELECT
       owner,
       table_name,
       partition_name,
       stale_stats,
       last_analyzed,
       num_rows,
       sample_size
FROM   dba_tab_statistics
WHERE  stale_stats = 'YES'
AND    owner NOT IN ('SYS','SYSTEM')
AND    object_type = 'TABLE'
ORDER BY last_analyzed NULLS FIRST, owner, table_name
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: Stale table statistics ===
PROMPT

-- End of file
