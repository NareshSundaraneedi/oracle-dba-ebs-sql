--------------------------------------------------------------------------------
-- File Name       : 17_check_optimizer_statistics.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 17 — stats on objects in the plan
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Stale/missing stats for objects referenced by the SQL_ID plan. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 17 — stats on objects in the plan
--------------------------------------------------------------------------------
-- 1. What the query does
--    Stale/missing stats for objects referenced by the SQL_ID plan.
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
SELECT DISTINCT p.object_owner, p.object_name, p.object_type,
       t.num_rows, t.last_analyzed, t.stale_stats
FROM v$sql_plan p
LEFT JOIN dba_tab_statistics t
       ON t.owner=p.object_owner AND t.table_name=p.object_name AND t.object_type='TABLE'
WHERE p.sql_id='&sql_id'
AND p.object_name IS NOT NULL
ORDER BY p.object_owner, p.object_name;

PROMPT
PROMPT === End of query: Step 17 — stats on objects in the plan ===
PROMPT

-- End of file
