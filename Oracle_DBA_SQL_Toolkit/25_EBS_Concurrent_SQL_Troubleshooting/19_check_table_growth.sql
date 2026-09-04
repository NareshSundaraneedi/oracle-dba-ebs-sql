--------------------------------------------------------------------------------
-- File Name       : 19_check_table_growth.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 19 — size of tables in the plan
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Segment size — a 10x data growth explains a 10x runtime without a plan change. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Step 19 — size of tables in the plan
--------------------------------------------------------------------------------
-- 1. What the query does
--    Segment size — a 10x data growth explains a 10x runtime without a plan change.
-- 2. Important columns
--    See SELECT list.
-- 3. How to interpret the output
--    Capture the output into the incident ticket before changing anything.
-- 4. What indicates a problem
--    Missing session or SQL_ID means the program is not in a DB call — check the request log.
-- 5. Recommended DBA action
--    Continue the next numbered script. Do not skip to kill.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs
SELECT s.owner, s.segment_name, s.segment_type, ROUND(s.bytes/1024/1024/1024,2) gb
FROM dba_segments s
WHERE (s.owner, s.segment_name) IN (
  SELECT object_owner, object_name FROM v$sql_plan WHERE sql_id='&sql_id' AND object_name IS NOT NULL)
ORDER BY s.bytes DESC;

PROMPT
PROMPT === End of query: Step 19 — size of tables in the plan ===
PROMPT

-- End of file
