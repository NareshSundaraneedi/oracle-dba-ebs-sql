--------------------------------------------------------------------------------
-- File Name       : 20_high_parse_rate.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : High parse rate
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: high CPU in parse, hard parses climbing. Initial: parse ratios, V$SQL not shared, logon rate. Evidence: two snapshots 60s apart of v$sysstat parses. Causes: literals, no binds, invalidations, connection per request. Fix: binds, session cursor cache, stop invalidating. Post-fix: parse/exec drops; CPU down.
--
-- Production playbook.  binds, session cursor cache, stop invalidating.
-- Post-fix: parse/exec drops; CPU down.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: High parse rate — queries
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
SELECT name, value FROM v$sysstat WHERE name LIKE 'parse count%' OR name='execute count';
SELECT sql_id, executions, parse_calls FROM gv$sql WHERE parse_calls>executions AND executions>0
ORDER BY parse_calls DESC FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: High parse rate — queries ===
PROMPT

-- End of file
