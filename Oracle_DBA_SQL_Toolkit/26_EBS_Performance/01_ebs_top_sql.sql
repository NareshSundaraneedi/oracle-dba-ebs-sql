--------------------------------------------------------------------------------
-- File Name       : 01_ebs_top_sql.sql
-- Category        : 26_EBS_Performance
-- Purpose         : Top SQL from sessions that look like EBS (APPS / MODULE set)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Ranks GV$SQL parsed by APPS. Difference vs 07/01: EBS-filtered so SYS RMAN SQL does not dominate.
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
-- QUERY 1: Top APPS SQL by elapsed
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SQL parsing_schema APPS.
-- 2. Important columns
--    SQL_ID, ELA_S, MODULE.
-- 3. How to interpret the output
--    MODULE often equals the concurrent program or form.
-- 4. What indicates a problem
--    One SQL_ID dominates APPS elapsed during the slowness window.
-- 5. Recommended DBA action
--    25 chain if it maps to a request; else 08_SQL_Tuning.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL
--------------------------------------------------------------------------------
SELECT sql_id, module, executions, ROUND(elapsed_time/1e6,1) ela_s,
       ROUND(cpu_time/1e6,1) cpu_s, buffer_gets, SUBSTR(sql_text,1,160) sql_text
FROM gv$sql WHERE parsing_schema_name='APPS' AND executions>0
ORDER BY elapsed_time DESC FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Top APPS SQL by elapsed ===
PROMPT

-- End of file
