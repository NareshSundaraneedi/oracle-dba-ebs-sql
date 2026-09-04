--------------------------------------------------------------------------------
-- File Name       : 02_execution_plan.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Display the actual cursor plan for a SQL_ID (DBMS_XPLAN)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Gets the plan of a cursor still in cache. Use ALLSTATS LAST if
-- the statement was executed with GATHER_PLAN_STATISTICS or
-- statistics_level=ALL (do not set ALL on production globally).
--
-- DISPLAY_CURSOR uses V$SQL_PLAN — no Diagnostics Pack required.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: DBMS_XPLAN.DISPLAY_CURSOR
--------------------------------------------------------------------------------
-- 1. What the query does
--    Calls DBMS_XPLAN for &sql_id and optional child.
-- 2. Important columns
--    PLAN_TABLE_OUTPUT.
-- 3. How to interpret the output
--    Look at cardinality estimates vs actuals (if ALLSTATS). Nested loops on large row sources, wrong join order, implicit conversions.
-- 4. What indicates a problem
--    Estimated rows 1, actual millions.
-- 5. Recommended DBA action
--    Fix stats, predicates, or add a baseline. Do not set optimizer_index_cost_adj as a first fix.
-- 6. Production cautions
--    Safe. statistics_level=ALL is NOT recommended instance-wide.
-- 7. Required privileges
--    SELECT on V_$SQL_PLAN, V_$SQL. Execute DBMS_XPLAN.
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs
DEFINE child  = 0

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', &child, 'TYPICAL +PEEKED_BINDS +OUTLINE'));

-- If you enabled rowsource stats for a single session test (not production-wide):
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', &child, 'ALLSTATS LAST +PEEKED_BINDS'));

PROMPT
PROMPT === End of query: DBMS_XPLAN.DISPLAY_CURSOR ===
PROMPT

-- End of file
