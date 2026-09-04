--------------------------------------------------------------------------------
-- File Name       : 23_connection_saturation.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : Connection / process saturation
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: ORA-00020/00018, listeners refuse. Initial: resource_limit, leak by machine, restricted, dead processes. Fix: leak first; raise processes only in a bounce window after math (PGA*processes). Post-fix: utilization < 70% at peak.
--
-- Production playbook.  leak first; raise processes only in a bounce window after math (PGA*processes).
-- Post-fix: utilization < 70% at peak.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Connection / process saturation — queries
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
SELECT resource_name, current_utilization, max_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT machine, COUNT(*) FROM gv$session GROUP BY machine ORDER BY 2 DESC FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT === End of query: Connection / process saturation — queries ===
PROMPT

-- End of file
