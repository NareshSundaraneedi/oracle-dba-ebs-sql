--------------------------------------------------------------------------------
-- File Name       : 17_ora_00600.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-00600 internal error
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: 00600 in alert with arguments [nnn]. Initial: first argument lookup on MOS, incident dump. Evidence: trace + SQL involved. Causes: Oracle bug, corruption, unsupported action. Fix: SR / patch. Do not keep retrying the same SQL in a tight loop. Post-fix: no recurrence after patch or workaround (event/_fix) approved by Support.
--
-- Production playbook.  SR / patch. Do not keep retrying the same SQL in a tight loop.
-- Post-fix: no recurrence after patch or workaround (event/_fix) approved by Support.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-00600 internal error — queries
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
SELECT name, value FROM v$diag_info WHERE name IN ('ADR Home','Active Problem Count','Active Incident Count');
PROMPT MOS: first 00600 argument + version 19.x. Package incidents with adrci.

PROMPT
PROMPT === End of query: ORA-00600 internal error — queries ===
PROMPT

-- End of file
