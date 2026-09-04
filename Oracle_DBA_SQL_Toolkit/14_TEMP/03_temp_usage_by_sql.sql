--------------------------------------------------------------------------------
-- File Name       : 03_temp_usage_by_sql.sql
-- Category        : 14_TEMP
-- Purpose         : TEMP aggregated by SQL_ID
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds the statement, not just the session (PX has many sessions per SQL).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: TEMP by SQL_ID
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group tempseg usage.
-- 2. Important columns
--    SQL_ID, MB, SESSIONS.
-- 3. How to interpret the output
--    PX slaves share a SQL_ID.
-- 4. What indicates a problem
--    A reporting SQL_ID consuming TEMP on all nodes.
-- 5. Recommended DBA action
--    Plan + workarea. Reduce parallel if it increased spill.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$TEMPSEG_USAGE
--------------------------------------------------------------------------------
SELECT sql_id, segtype, COUNT(*) sessions, ROUND(SUM(blocks)*8/1024,1) mb
FROM gv$tempseg_usage
GROUP BY sql_id, segtype
ORDER BY mb DESC;

PROMPT
PROMPT === End of query: TEMP by SQL_ID ===
PROMPT

-- End of file
