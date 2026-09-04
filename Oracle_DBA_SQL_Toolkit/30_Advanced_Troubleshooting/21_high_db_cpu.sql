--------------------------------------------------------------------------------
-- File Name       : 21_high_db_cpu.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : High DB CPU playbook
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: DB CPU close to DB time and host saturated. Same chain as 02 with emphasis on time model and top CPU SQL. Fix: reduce CPU SQL (functions, NL joins). Post-fix: DB CPU % down.
--
-- Production playbook.  reduce CPU SQL (functions, NL joins). Post-fix: DB CPU % down.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: High DB CPU playbook — queries
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
SELECT stat_name, ROUND(value/1e6,1) s FROM v$sys_time_model WHERE stat_name IN ('DB time','DB CPU','sql execute elapsed time','parse time elapsed');
SELECT sql_id, ROUND(cpu_time/1e6,1) cpu_s, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,120) t
FROM v$sql ORDER BY cpu_time DESC FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT === End of query: High DB CPU playbook — queries ===
PROMPT

-- End of file
