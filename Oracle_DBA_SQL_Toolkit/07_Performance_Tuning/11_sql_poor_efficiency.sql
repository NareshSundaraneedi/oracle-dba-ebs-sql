--------------------------------------------------------------------------------
-- File Name       : 11_sql_poor_efficiency.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : SQL with terrible buffer gets per row (inefficient access)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Gets-per-row is a rough efficiency metric. High values mean the
-- engine touches many blocks to produce few rows (bad join, missing index,
-- or implicit conversion).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Inefficient SQL by gets per row
--------------------------------------------------------------------------------
-- 1. What the query does
--    Orders GV$SQL by buffer_gets/rows_processed with guards.
-- 2. Important columns
--    SQL_ID, GETS_PER_ROW, GETS_PER_EXEC.
-- 3. How to interpret the output
--    Hundreds of gets/row on a multi-table join is a smoking gun.
-- 4. What indicates a problem
--    Gets/row jumped after a plan change.
-- 5. Recommended DBA action
--    Inspect the plan for nested loops on large row sources.
-- 6. Production cautions
--    Safe. rows_processed = 0 statements are excluded.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
SELECT
       sql_id,
       plan_hash_value,
       executions,
       buffer_gets,
       rows_processed,
       ROUND(buffer_gets/NULLIF(rows_processed,0)) AS gets_per_row,
       ROUND(buffer_gets/NULLIF(executions,0)) AS gets_per_exec,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  rows_processed > 100
AND    buffer_gets > 100000
AND    parsing_schema_name NOT IN ('SYS','SYSTEM')
ORDER BY buffer_gets/NULLIF(rows_processed,0) DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Inefficient SQL by gets per row ===
PROMPT

-- End of file
