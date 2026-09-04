--------------------------------------------------------------------------------
-- File Name       : 24_full_table_scans.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : SQL currently doing or recently doing full table scans
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Uses V$SQL_PLAN for TABLE ACCESS FULL in cache. Not every FTS is
-- bad (small tables, reporting). Filter by cost/bytes.
--
-- V$SQL_PLAN is EE and pack-free. Historical plans in DBA_HIST_SQL_PLAN need Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: FTS operations in cached plans
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins V$SQL_PLAN to V$SQL for TABLE ACCESS FULL.
-- 2. Important columns
--    SQL_ID, OBJECT_OWNER, OBJECT_NAME, CARDINALITY, BYTES.
-- 3. How to interpret the output
--    FTS on a multi-GB table in an OLTP module is the problem set.
-- 4. What indicates a problem
--    Scattered read waits + FTS on a large transaction table.
-- 5. Recommended DBA action
--    Confirm predicates and indexes. Check implicit conversions.
-- 6. Production cautions
--    Safe. Plan table can be large — limited fetch.
-- 7. Required privileges
--    SELECT on V_$SQL_PLAN, V_$SQL
--------------------------------------------------------------------------------
SELECT
       p.sql_id,
       p.plan_hash_value,
       p.object_owner,
       p.object_name,
       p.cardinality,
       p.bytes,
       p.cost,
       ROUND(s.elapsed_time/1e6,1) AS elapsed_s,
       SUBSTR(s.sql_text,1,140) AS sql_text
FROM   v$sql_plan p
JOIN   v$sql s ON s.sql_id = p.sql_id AND s.plan_hash_value = p.plan_hash_value AND s.child_number = p.child_number
WHERE  p.operation = 'TABLE ACCESS'
AND    p.options LIKE '%FULL%'
AND    p.object_owner NOT IN ('SYS','SYSTEM')
ORDER BY p.bytes DESC NULLS LAST
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: FTS operations in cached plans ===
PROMPT

-- End of file
