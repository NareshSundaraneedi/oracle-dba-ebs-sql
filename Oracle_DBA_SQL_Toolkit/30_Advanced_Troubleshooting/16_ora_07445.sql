--------------------------------------------------------------------------------
-- File Name       : 16_ora_07445.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-07445 exception (process crash)
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: 07445 in alert, process died, possibly instance stable. Initial: Diag incident count, alert text, associated SQL if any. Evidence: incident dump / cdump — package for Support. Causes: bug, bad bind, OS, corrupt block. Fix: MOS/SR with the incident. Do not delete incidents before packaging. Do not bounce unless looping. Post-fix: no new 07445; apply recommended patch in a window.
--
-- Production playbook.  MOS/SR with the incident. Do not delete incidents before packaging. Do not bounce unless looping.
-- Post-fix: no new 07445; apply recommended patch in a window.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-07445 exception (process crash) — queries
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
SELECT name, value FROM v$diag_info WHERE name IN ('ADR Home','Active Problem Count','Active Incident Count','Diag Alert');
PROMPT Use adrci: SHOW PROBLEM; SHOW INCIDENT; IPS PACK.
PROMPT Do not interpret 07445 as a SQL tune issue first.

PROMPT
PROMPT === End of query: ORA-07445 exception (process crash) — queries ===
PROMPT

-- End of file
