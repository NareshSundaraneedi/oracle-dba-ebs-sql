--------------------------------------------------------------------------------
-- File Name       : 09_sql_high_io.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : SQL with high physical I/O per execution
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Per-execution disk reads. Complements 04.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Highest disk reads per execution
--------------------------------------------------------------------------------
-- 1. What the query does
--    Orders GV$SQL by disk_reads/executions.
-- 2. Important columns
--    SQL_ID, READS_PER_EXEC.
-- 3. How to interpret the output
--    Direct path reads on large FTS show up here.
-- 4. What indicates a problem
--    Reads/exec in the millions on an OLTP SQL.
-- 5. Recommended DBA action
--    Check 24_full_table_scans and the plan.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
SELECT
       sql_id,
       plan_hash_value,
       module,
       executions,
       ROUND(disk_reads/NULLIF(executions,0)) AS reads_per_exec,
       ROUND(buffer_gets/NULLIF(executions,0)) AS gets_per_exec,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    disk_reads > 10000
ORDER BY disk_reads/executions DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Highest disk reads per execution ===
PROMPT

-- End of file
