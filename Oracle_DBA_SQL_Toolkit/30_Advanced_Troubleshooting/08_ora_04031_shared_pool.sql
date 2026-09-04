--------------------------------------------------------------------------------
-- File Name       : 08_ora_04031_shared_pool.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-04031 shared pool
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: 04031 in alert / sessions failing to parse. Initial: request_failures, reserved pool, large unshared SQL, recent flush. Evidence: 04031 trace, SGASTAT. Causes: fragmentation, literal SQL, flush, undersized pool. Fix: stop flushing. Find literal SQL. Increase pool only after evidence. NOT a bounce-first problem unless frozen. Post-fix: request_failures stable, parses succeed.
--
-- Production playbook.  stop flushing. Find literal SQL. Increase pool only after evidence. NOT a bounce-first problem unless frozen.
-- Post-fix: request_failures stable, parses succeed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-04031 shared pool — queries
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
SELECT request_failures, last_failure_size, free_space FROM v$shared_pool_reserved;
SELECT name, ROUND(bytes/1024/1024,1) mb FROM v$sgastat WHERE pool='shared pool' AND bytes>20*1024*1024 ORDER BY bytes DESC;
SELECT sql_id, COUNT(*) children FROM gv$sql GROUP BY sql_id HAVING COUNT(*)>50 ORDER BY children DESC FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT === End of query: ORA-04031 shared pool — queries ===
PROMPT

-- End of file
