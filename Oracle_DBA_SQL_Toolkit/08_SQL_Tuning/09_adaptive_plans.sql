--------------------------------------------------------------------------------
-- File Name       : 09_adaptive_plans.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Identify adaptive plans in cache
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- 19c adaptive plans can switch join methods at runtime.
-- DISPLAY_CURSOR with ADAPTIVE shows the resolved plan.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Adaptive notes in plans
--------------------------------------------------------------------------------
-- 1. What the query does
--    Searches V$SQL_PLAN for adaptive operations / notes.
-- 2. Important columns
--    SQL_ID, OPERATION, OPTIONS.
-- 3. How to interpret the output
--    HYBRID HASH / adaptive statistics notes indicate adaptive behavior.
-- 4. What indicates a problem
--    A plan that flips during a long EBS job, changing runtime mid-flight.
-- 5. Recommended DBA action
--    For a single critical SQL, consider OPT_PARAM('_optimizer_adaptive_plans','false') via a patch/baseline — Support/change only.
-- 6. Production cautions
--    Safe to query. Do not disable adaptive features instance-wide mid-incident.
-- 7. Required privileges
--    SELECT on V_$SQL_PLAN, V_$SQL
--------------------------------------------------------------------------------
SELECT DISTINCT
       p.sql_id,
       p.plan_hash_value,
       p.operation,
       p.options
FROM   v$sql_plan p
WHERE  p.options LIKE '%ADAPTIVE%'
OR     p.operation LIKE '%ADAPTIVE%'
FETCH FIRST 40 ROWS ONLY;

PROMPT For a specific SQL:
PROMPT SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id',0,'ADAPTIVE'));

PROMPT
PROMPT === End of query: Adaptive notes in plans ===
PROMPT

-- End of file
