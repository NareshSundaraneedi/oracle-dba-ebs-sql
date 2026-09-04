--------------------------------------------------------------------------------
-- File Name       : 10_cardinality_feedback.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Statistics / cardinality feedback usage on cursors
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- IS_REOPTIMIZABLE and USE_FEEDBACK_STATS (names vary) show
-- whether Oracle reparsed after seeing actual cardinalities.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Reoptimization flags
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$SQL columns related to reoptimization.
-- 2. Important columns
--    SQL_ID, IS_REOPTIMIZABLE, EXECUTIONS.
-- 3. How to interpret the output
--    Many reoptimizable cursors mean the first execution used a guess.
-- 4. What indicates a problem
--    First execution of a concurrent program is 10x slower than the second.
-- 5. Recommended DBA action
--    Improve stats/dynamic sampling for that SQL rather than running it twice.
-- 6. Production cautions
--    Safe. Column names are valid on 19c V$SQL (IS_REOPTIMIZABLE).
-- 7. Required privileges
--    SELECT on GV_$SQL
--
-- Oracle 19c.
--------------------------------------------------------------------------------
SELECT
       sql_id,
       child_number,
       is_reoptimizable,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s,
       SUBSTR(sql_text,1,140) AS sql_text
FROM   gv$sql
WHERE  is_reoptimizable = 'Y'
ORDER BY elapsed_time DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Reoptimization flags ===
PROMPT

-- End of file
