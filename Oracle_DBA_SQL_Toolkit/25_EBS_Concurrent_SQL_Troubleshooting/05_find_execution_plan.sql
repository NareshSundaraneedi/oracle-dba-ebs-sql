--------------------------------------------------------------------------------
-- File Name       : 05_find_execution_plan.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 5 — execution plan
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DISPLAY_CURSOR for the child. No Tuning Pack required. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 5 — execution plan
--------------------------------------------------------------------------------
-- 1. What the query does
--    DISPLAY_CURSOR for the child. No Tuning Pack required.
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
DEFINE child = 0
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', &child, 'TYPICAL +PEEKED_BINDS'));

PROMPT
PROMPT === End of query: Step 5 — execution plan ===
PROMPT

-- End of file
