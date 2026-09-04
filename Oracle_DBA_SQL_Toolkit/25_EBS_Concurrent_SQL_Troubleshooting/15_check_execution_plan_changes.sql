--------------------------------------------------------------------------------
-- File Name       : 15_check_execution_plan_changes.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 15 — plan hashes over time (AWR)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- LICENSING: Diagnostics Pack for DBA_HIST_SQLSTAT. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS. Diagnostics Pack required.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Step 15 — plan hashes over time (AWR)
--------------------------------------------------------------------------------
-- 1. What the query does
--    LICENSING: Diagnostics Pack for DBA_HIST_SQLSTAT.
-- 2. Important columns
--    See SELECT list.
-- 3. How to interpret the output
--    Capture the output into the incident ticket before changing anything.
-- 4. What indicates a problem
--    Missing session or SQL_ID means the program is not in a DB call — check the request log.
-- 5. Recommended DBA action
--    Continue the next numbered script. Do not skip to kill.
-- 6. Production cautions
--    Safe. AWR script needs Diagnostics Pack.
-- 7. Required privileges
--    APPS + SELECT_CATALOG_ROLE
--
-- Diagnostics Pack required.
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs
SELECT TO_CHAR(sn.begin_interval_time,'DD-MON HH24:MI') snap_time, st.plan_hash_value,
       st.executions_delta,
       ROUND(st.elapsed_time_delta/NULLIF(st.executions_delta,0)/1e6,3) ela_per_exec_s
FROM dba_hist_sqlstat st
JOIN dba_hist_snapshot sn ON sn.snap_id=st.snap_id AND sn.dbid=st.dbid AND sn.instance_number=st.instance_number
WHERE st.sql_id='&sql_id' AND sn.begin_interval_time>SYSDATE-14
ORDER BY sn.begin_interval_time;

PROMPT
PROMPT === End of query: Step 15 — plan hashes over time (AWR) ===
PROMPT

-- End of file
