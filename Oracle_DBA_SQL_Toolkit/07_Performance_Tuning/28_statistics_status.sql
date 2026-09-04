--------------------------------------------------------------------------------
-- File Name       : 28_statistics_status.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Stats freshness summary by schema
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Counts tables with/without stats and last analyzed age.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Statistics coverage by owner
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates DBA_TABLES last_analyzed.
-- 2. Important columns
--    OWNER, TABLES, WITH_STATS, STALE_30D.
-- 3. How to interpret the output
--    EBS product schemas should be gathered with the approved EBS stats procedure, not ad-hoc schema stats during peak.
-- 4. What indicates a problem
--    A large transactional schema with last_analyzed months ago OR stats gathered mid-day causing parse storms.
-- 5. Recommended DBA action
--    Use FND_STATS / Concurrent Gather Schema Statistics for EBS. See 30.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TABLES
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       owner,
       COUNT(*) AS tables,
       SUM(CASE WHEN last_analyzed IS NULL THEN 1 ELSE 0 END) AS no_stats,
       SUM(CASE WHEN last_analyzed < SYSDATE - 30 THEN 1 ELSE 0 END) AS older_than_30d,
       MAX(last_analyzed) AS newest_stats
FROM   dba_tables
WHERE  owner NOT IN ('SYS','SYSTEM','XDB')
AND    temporary = 'N'
GROUP BY owner
ORDER BY no_stats DESC, owner;

PROMPT
PROMPT === End of query: Statistics coverage by owner ===
PROMPT

-- End of file
