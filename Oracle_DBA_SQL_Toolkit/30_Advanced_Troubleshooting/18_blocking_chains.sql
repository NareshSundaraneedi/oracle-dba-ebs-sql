--------------------------------------------------------------------------------
-- File Name       : 18_blocking_chains.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : Blocking chains (advanced playbook)
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: sessions hang, enq waits. Initial: 10/01, 10/11 tree, object, inactive blocker. Evidence: tree + locked objects + SQL_IDs. Causes: uncommitted form, unindexed FK TM, batch vs OLTP on same rows. Fix: user commit or generated disconnect of ROOT blocker only. Post-fix: no waiters; business transaction confirmed.
--
-- Production playbook.  user commit or generated disconnect of ROOT blocker only.
-- Post-fix: no waiters; business transaction confirmed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Blocking chains (advanced playbook) — queries
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
SELECT inst_id, sid, serial#, username, status, event, blocking_session, blocking_instance, sql_id, module, last_call_et
FROM gv$session WHERE blocking_session IS NOT NULL OR sid IN (
  SELECT blocking_session FROM gv$session WHERE blocking_session IS NOT NULL)
ORDER BY blocking_instance, blocking_session, sid;

PROMPT
PROMPT === End of query: Blocking chains (advanced playbook) — queries ===
PROMPT

-- End of file
