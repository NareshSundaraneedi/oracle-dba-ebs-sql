--------------------------------------------------------------------------------
-- File Name       : 03_sql_plan_history.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Historical plans from AWR (DISPLAY_AWR)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows plans that are no longer in cache. Different from
-- 07_Performance_Tuning/13 which is metrics-over-time; this prints the plan text.
--
-- LICENSING: Diagnostics Pack required for DBA_HIST_SQL_PLAN / DISPLAY_AWR.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AWR plans for a SQL_ID
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lists plan hashes then DISPLAY_AWR.
-- 2. Important columns
--    PLAN_HASH_VALUE, TIMESTAMP, PLAN_TABLE_OUTPUT.
-- 3. How to interpret the output
--    Compare two plan hashes from before/after the incident.
-- 4. What indicates a problem
--    The current plan is the expensive one and the old hash is known-good.
-- 5. Recommended DBA action
--    Load a SQL plan baseline from the good AWR plan (Tuning Pack / SPM).
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on DBA_HIST_SQL_PLAN. EXECUTE DBMS_XPLAN.
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs

SELECT DISTINCT plan_hash_value, timestamp
FROM   dba_hist_sql_plan
WHERE  sql_id = '&sql_id'
ORDER BY timestamp DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_AWR('&sql_id'));

PROMPT
PROMPT === End of query: AWR plans for a SQL_ID ===
PROMPT

-- End of file
