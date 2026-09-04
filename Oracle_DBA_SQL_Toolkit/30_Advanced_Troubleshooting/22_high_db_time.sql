--------------------------------------------------------------------------------
-- File Name       : 22_high_db_time.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : High DB time playbook
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: AAS high. DB time is the load metric. Initial: CPU vs wait split, top wait, top SQL elapsed, EBS running requests. Fix: the dominant wait class (09) or SQL (07/08). Post-fix: AAS ≈ baseline.
--
-- Production playbook.  the dominant wait class (09) or SQL (07/08). Post-fix: AAS ≈ baseline.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: High DB time playbook — queries
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
--    SELECT_CATALOG_ROLE + APPS
--------------------------------------------------------------------------------
SELECT stat_name, ROUND(value/1e6,1) s FROM v$sys_time_model WHERE stat_name IN ('DB time','DB CPU');
SELECT event, ROUND(time_waited_micro/1e6,1) time_s FROM v$system_event WHERE wait_class<>'Idle' ORDER BY time_waited_micro DESC FETCH FIRST 12 ROWS ONLY;
SELECT request_id, phase_code, ROUND((SYSDATE-actual_start_date)*24*60,1) mins FROM fnd_concurrent_requests WHERE phase_code='R';

PROMPT
PROMPT === End of query: High DB time playbook — queries ===
PROMPT

-- End of file
