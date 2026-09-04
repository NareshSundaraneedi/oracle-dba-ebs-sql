--------------------------------------------------------------------------------
-- File Name       : 26_missing_indexes.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Heuristic missing-index suspects (unindexed FK + FTS), not a magic advisor
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- There is no safe 'create these indexes' list. This combines
-- unindexed FK (from 05_Objects/07) with large FTS objects as suspects
-- for a human to review.
--
-- SQL Access Advisor requires Tuning Pack and is not auto-run here. This script only lists heuristics.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Suspect objects appearing in FTS
--------------------------------------------------------------------------------
-- 1. What the query does
--    Distinct large objects from V$SQL_PLAN FULL plus reminder to check FKs.
-- 2. Important columns
--    OBJECT_OWNER, OBJECT_NAME, SQL_COUNT.
-- 3. How to interpret the output
--    Frequency in plans != missing index. Always open the SQL.
-- 4. What indicates a problem
--    A custom table in many FTS plans.
-- 5. Recommended DBA action
--    Manual design. Do not create 10 indexes from this list.
-- 6. Production cautions
--    Safe. Not a substitute for SQL Tuning Advisor (licensed).
-- 7. Required privileges
--    SELECT on V_$SQL_PLAN
--------------------------------------------------------------------------------
SELECT
       object_owner,
       object_name,
       COUNT(DISTINCT sql_id) AS sql_count,
       ROUND(MAX(bytes)/1024/1024,1) AS max_est_mb
FROM   v$sql_plan
WHERE  operation = 'TABLE ACCESS'
AND    options LIKE '%FULL%'
AND    object_owner NOT IN ('SYS','SYSTEM')
GROUP BY object_owner, object_name
ORDER BY sql_count DESC, max_est_mb DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT Also run ../05_Objects/07_foreign_keys.sql for unindexed FK suspects.

PROMPT
PROMPT === End of query: Suspect objects appearing in FTS ===
PROMPT

-- End of file
