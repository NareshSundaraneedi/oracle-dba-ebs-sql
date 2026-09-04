--------------------------------------------------------------------------------
-- File Name       : 14_check_execution_count.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 14 — executions of the SQL_ID
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Is this a long single execution or a loop? Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 14 — executions of the SQL_ID
--------------------------------------------------------------------------------
-- 1. What the query does
--    Is this a long single execution or a loop?
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
SELECT inst_id, child_number, executions, ROUND(elapsed_time/1e6,1) ela_s,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,3) ela_per_exec_s
FROM gv$sql WHERE sql_id='&sql_id';

PROMPT
PROMPT === End of query: Step 14 — executions of the SQL_ID ===
PROMPT

-- End of file
