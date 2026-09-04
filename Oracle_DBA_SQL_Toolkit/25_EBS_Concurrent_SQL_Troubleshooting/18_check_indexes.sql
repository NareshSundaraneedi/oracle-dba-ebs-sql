--------------------------------------------------------------------------------
-- File Name       : 18_check_indexes.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 18 — indexes on tables used by the SQL
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Index list + unusable flag for plan objects. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 18 — indexes on tables used by the SQL
--------------------------------------------------------------------------------
-- 1. What the query does
--    Index list + unusable flag for plan objects.
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
SELECT i.table_owner, i.table_name, i.index_name, i.uniqueness, i.status, i.visibility
FROM dba_indexes i
WHERE (i.table_owner, i.table_name) IN (
  SELECT object_owner, object_name FROM v$sql_plan
  WHERE sql_id='&sql_id' AND operation LIKE 'TABLE%')
ORDER BY i.table_owner, i.table_name, i.index_name;

PROMPT
PROMPT === End of query: Step 18 — indexes on tables used by the SQL ===
PROMPT

-- End of file
