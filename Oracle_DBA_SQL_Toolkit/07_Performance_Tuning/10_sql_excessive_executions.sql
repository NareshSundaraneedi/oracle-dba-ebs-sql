--------------------------------------------------------------------------------
-- File Name       : 10_sql_excessive_executions.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Very chatty SQL (high executions, not necessarily high elapsed)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds statements that execute extremely often. Typical EBS Forms
-- validation SQL. Different from 05 because a minimum executions floor
-- and ela/exec ceiling highlights 'death by a thousand cuts'.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Chatty SQL
--------------------------------------------------------------------------------
-- 1. What the query does
--    High executions with small per-exec elapsed.
-- 2. Important columns
--    SQL_ID, EXECUTIONS, ELA_PER_EXEC_MS.
-- 3. How to interpret the output
--    These often need application caching or a bind/plan fix, not a bigger buffer cache.
-- 4. What indicates a problem
--    Executions in tens of millions since startup from one module.
-- 5. Recommended DBA action
--    Work with the developer. Consider result cache only if deterministic and licensed/appropriate.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       sql_id,
       module,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e3,2) AS ela_per_exec_ms,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 100000
ORDER BY executions DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Chatty SQL ===
PROMPT

-- End of file
