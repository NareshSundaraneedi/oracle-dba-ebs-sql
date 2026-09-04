--------------------------------------------------------------------------------
-- File Name       : 06_sql_by_instance.sql
-- Category        : 15_RAC
-- Purpose         : Same SQL_ID elapsed by instance
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds SQL that is expensive only on one node (plan difference, data, or cache).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: GV$SQL by inst
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group elapsed by sql_id, inst_id.
-- 2. Important columns
--    SQL_ID, INST, ELA_S.
-- 3. How to interpret the output
--    Same plan_hash on both vs different.
-- 4. What indicates a problem
--    10x elapsed on one instance only.
-- 5. Recommended DBA action
--    Check child plans per inst. Interconnect for that SQL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
SELECT sql_id, inst_id, plan_hash_value, executions,
       ROUND(elapsed_time/1e6,1) ela_s
FROM gv$sql WHERE elapsed_time > 1e7
ORDER BY sql_id, inst_id;

PROMPT
PROMPT === End of query: GV$SQL by inst ===
PROMPT

-- End of file
