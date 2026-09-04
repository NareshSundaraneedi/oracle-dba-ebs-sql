--------------------------------------------------------------------------------
-- File Name       : 14_largest_segments.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Top segments by size right now
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Point-in-time largest segments. Use this when you do not have AWR
-- or you need an immediate answer.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top 50 segments
--------------------------------------------------------------------------------
-- 1. What the query does
--    Ranks DBA_SEGMENTS by BYTES.
-- 2. Important columns
--    OWNER, SEGMENT_NAME, SEGMENT_TYPE, SIZE_GB, TABLESPACE_NAME.
-- 3. How to interpret the output
--    EBS: large FND, WF, GL, and interface tables are common. Compare to last month's ranking.
-- 4. What indicates a problem
--    A new segment in the top 10 that was not there last week.
-- 5. Recommended DBA action
--    Drill into table vs index. Check purge programs.
-- 6. Production cautions
--    Safe. Slight dictionary cost.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       owner,
       segment_name,
       partition_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb
FROM   dba_segments
ORDER BY bytes DESC
FETCH FIRST 50 ROWS ONLY;

PROMPT
PROMPT === End of query: Top 50 segments ===
PROMPT

-- End of file
