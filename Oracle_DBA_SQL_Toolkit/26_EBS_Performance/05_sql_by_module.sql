--------------------------------------------------------------------------------
-- File Name       : 05_sql_by_module.sql
-- Category        : 26_EBS_Performance
-- Purpose         : SQL cache filtered to one MODULE
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE module_p. Use the form or program short name.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL by module
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SQL.module filter.
-- 2. Important columns
--    SQL_ID, ELA, TEXT.
-- 3. How to interpret the output
--    Chatty forms have many SQL_IDs; concurrent usually one heavy SQL.
-- 4. What indicates a problem
--    New expensive SQL_ID in a standard form after customization.
-- 5. Recommended DBA action
--    08_SQL_Tuning.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
DEFINE module_p = %FNDSCSGN%
SELECT sql_id, executions, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,180) sql_text
FROM gv$sql WHERE module LIKE '&module_p' ORDER BY elapsed_time DESC FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: SQL by module ===
PROMPT

-- End of file
