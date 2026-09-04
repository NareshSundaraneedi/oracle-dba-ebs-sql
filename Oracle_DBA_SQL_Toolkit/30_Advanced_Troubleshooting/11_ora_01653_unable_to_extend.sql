--------------------------------------------------------------------------------
-- File Name       : 11_ora_01653_unable_to_extend.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-01653/01654 unable to extend table/index
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: DML fails extending a segment. Initial: tablespace used vs max, autoextend, largest chunk, file MAXSIZE. Evidence: error text has segment and tablespace. Causes: full TS, autoextend off, smallfile 32GB ceiling, fragmentation of UNIFORM. Fix: add datafile / raise MAXSIZE. Then find why it grew (purge). Post-fix: DML succeeds; used_pct_max < 85.
--
-- Production playbook.  add datafile / raise MAXSIZE. Then find why it grew (purge).
-- Post-fix: DML succeeds; used_pct_max < 85.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-01653/01654 unable to extend table/index — queries
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
-- DEFINE ts = APPS_TS_TX_DATA
SELECT file_id, file_name, autoextensible, ROUND(bytes/1024/1024/1024,2) gb, ROUND(maxbytes/1024/1024/1024,2) max_gb
FROM dba_data_files WHERE tablespace_name='&ts';
SELECT ROUND(MAX(bytes)/1024/1024,1) largest_free_mb FROM dba_free_space WHERE tablespace_name='&ts';

PROMPT
PROMPT === End of query: ORA-01653/01654 unable to extend table/index — queries ===
PROMPT

-- End of file
