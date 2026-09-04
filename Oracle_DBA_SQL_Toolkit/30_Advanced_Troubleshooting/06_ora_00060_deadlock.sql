--------------------------------------------------------------------------------
-- File Name       : 06_ora_00060_deadlock.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-00060 deadlock
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: ORA-00060 in app / alert. Initial: alert log deadlock graph, traces in Diag Trace. Evidence: two SQL statements and objects from the trace. Causes: locking order, missing FK index (TM), bitmap indexes on OLTP. Fix: application lock order; unindexed FK (05/07). INITRANS is rarely the fix. Post-fix: no repeated 00060 on those tables.
--
-- Production playbook.  application lock order; unindexed FK (05/07). INITRANS is rarely the fix.
-- Post-fix: no repeated 00060 on those tables.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-00060 deadlock — queries
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
SELECT name, value FROM v$diag_info WHERE name IN ('Diag Trace','ADR Home');
PROMPT Open the ORA-00060 trace listed in the alert log. Capture Deadlock graph + SQL.
SELECT sid, event, blocking_session, sql_id FROM gv$session WHERE event LIKE 'enq:%';

PROMPT
PROMPT === End of query: ORA-00060 deadlock — queries ===
PROMPT

-- End of file
