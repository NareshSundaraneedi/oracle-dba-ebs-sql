--------------------------------------------------------------------------------
-- File Name       : 01_database_suddenly_slow.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : Database suddenly slow
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: users say everything is slow. Initial checks: instance up, AAS/CPU vs wait, blockers, top SQL, archive dest. Evidence: spool this file, alert log around the start time, OS vmstat. Root causes: lock storm, plan flip, I/O, archiver hang, login storm, RAC imbalance. Fix: follow the branch this script points to — do not bounce first. Post-fix: AAS back to baseline, no blockers, top SQL sane.
--
-- Production playbook.  follow the branch this script points to — do not bounce first.
-- Post-fix: AAS back to baseline, no blockers, top SQL sane.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database suddenly slow — queries
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
SELECT 'INSTANCE' k, instance_name||' '||status||' up='||TO_CHAR(startup_time,'DD-MON HH24:MI') v FROM v$instance
UNION ALL SELECT 'ROLE', database_role||' '||open_mode FROM v$database
UNION ALL SELECT 'BLOCKERS', TO_CHAR(COUNT(*)) FROM gv$session WHERE blocking_session IS NOT NULL
UNION ALL SELECT 'ACTIVE_USERS', TO_CHAR(COUNT(*)) FROM gv$session WHERE type='USER' AND status='ACTIVE'
UNION ALL SELECT 'ARCH_ERROR', NVL(MAX(error),'none') FROM v$archive_dest WHERE dest_id=1;
SELECT event, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND wait_class<>'Idle' GROUP BY event ORDER BY 2 DESC;
SELECT sql_id, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND sql_id IS NOT NULL GROUP BY sql_id ORDER BY 2 DESC FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT === End of query: Database suddenly slow — queries ===
PROMPT

-- End of file
