--------------------------------------------------------------------------------
-- File Name       : 25_index_usage.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Index usage from DBA_INDEX_USAGE (12.2+) or monitoring
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- 12.2+ DBA_INDEX_USAGE tracks access when _iut_stat / index usage
-- tracking is available (19c has DBA_INDEX_USAGE). Older approach is
-- ALTER INDEX MONITORING USAGE (not enabled here).
--
-- Oracle 19c DBA_INDEX_USAGE. Absence of usage is not proof an index is unused (feature window, reset).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Index usage tracking
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_INDEX_USAGE ordered by total_access_count.
-- 2. Important columns
--    NAME, TOTAL_ACCESS_COUNT, TOTAL_EXEC_COUNT, LAST_USED.
-- 3. How to interpret the output
--    Zero access over a full business cycle is a drop candidate — still verify uniqueness/FK.
-- 4. What indicates a problem
--    A huge index never used (space waste) vs a critical unique index used rarely.
-- 5. Recommended DBA action
--    Do not drop unique/PK/FK-supporting indexes. See 27.
-- 6. Production cautions
--    Safe. Tracking is sampled / since last reset.
-- 7. Required privileges
--    SELECT on DBA_INDEX_USAGE, DBA_INDEXES
--
-- Oracle 19c (DBA_INDEX_USAGE).
--------------------------------------------------------------------------------
SELECT
       owner,
       name,
       total_access_count,
       total_exec_count,
       total_rows_returned,
       last_used
FROM   dba_index_usage
ORDER BY total_access_count DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;

PROMPT
PROMPT === End of query: Index usage tracking ===
PROMPT

-- End of file
