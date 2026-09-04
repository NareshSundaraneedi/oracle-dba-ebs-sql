--------------------------------------------------------------------------------
-- File Name       : 04_sessions_suddenly_increase.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : Sessions suddenly increase
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: session count spike, possible ORA-00018/00020. Initial: resource_limit, sessions by machine/program, inactive vs active. Evidence: listener log, app pool config. Causes: connection leak, retry storm, scan of a dropped service. Fix: fix the pool. Kill only leaked inactives with generated commands (06/16). Post-fix: current_utilization headroom > 20%.
--
-- Production playbook.  fix the pool. Kill only leaked inactives with generated commands (06/16).
-- Post-fix: current_utilization headroom > 20%.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Sessions suddenly increase — queries
--------------------------------------------------------------------------------
-- 1. What the query does
--    Playbook queries for this symptom.
-- 2. Important columns
--    See SELECT list / PROMPT for evidence to collect.
-- 3. How to interpret the output
--    Work Symptom → Initial checks → these SQL → Evidence → Root cause → Fix → Post-fix as in the file header DESCRIPTION.
-- 4. What indicates a problem
--    Matches the symptom in the file name.
-- 5. Recommended DBA action
--    See DESCRIPTION recommended fix. No destructive SQL is auto-run.
-- 6. Production cautions
--    Safe to query. Bounces, kills, and parameter changes are out of band.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT resource_name, current_utilization, max_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('sessions','processes');
SELECT machine, program, COUNT(*) FROM gv$session WHERE type='USER' GROUP BY machine, program ORDER BY COUNT(*) DESC FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: Sessions suddenly increase — queries ===
PROMPT

-- End of file
