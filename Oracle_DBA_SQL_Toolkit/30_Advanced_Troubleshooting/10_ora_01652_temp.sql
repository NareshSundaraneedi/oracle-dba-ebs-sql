--------------------------------------------------------------------------------
-- File Name       : 10_ora_01652_temp.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-01652 unable to extend TEMP
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: sort/hash fails 01652. Initial: temp usage, session TEMP, SQL_ID, PGA spills. Evidence: this spool. Causes: undersized TEMP, bad plan hash join, too much PX. Fix: add tempfile OR tune SQL. Shrinking TEMP mid-incident is wrong. Post-fix: statement succeeds; used_pct drops after the job.
--
-- Production playbook.  add tempfile OR tune SQL. Shrinking TEMP mid-incident is wrong.
-- Post-fix: statement succeeds; used_pct drops after the job.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-01652 unable to extend TEMP — queries
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
SELECT tablespace_name, ROUND((tablespace_size-free_space)*100/NULLIF(tablespace_size,0),1) used_pct FROM dba_temp_free_space;
SELECT sid, sql_id, segtype, ROUND(blocks*8/1024,1) mb FROM gv$tempseg_usage ORDER BY blocks DESC;

PROMPT
PROMPT === End of query: ORA-01652 unable to extend TEMP — queries ===
PROMPT

-- End of file
