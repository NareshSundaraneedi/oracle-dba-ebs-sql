--------------------------------------------------------------------------------
-- File Name       : 09_ora_04030_pga_memory.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-04030 PGA / process memory
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: 04030 in process, possible OS OOM. Initial: pga_aggregate_limit, top PGA process, workarea, hugepages leftover. Evidence: 04030 trace shows which heap. Causes: huge hash, PL/SQL collections, PX slaves, OS limit. Fix: tune SQL / limit arrays. Raise PGA only with RAM headroom. Check ulimit. Post-fix: process completes; PGA top consumers drop.
--
-- Production playbook.  tune SQL / limit arrays. Raise PGA only with RAM headroom. Check ulimit.
-- Post-fix: process completes; PGA top consumers drop.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-04030 PGA / process memory — queries
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
SELECT name, display_value FROM v$parameter WHERE name LIKE 'pga%';
SELECT inst_id, spid, program, ROUND(pga_alloc_mem/1024/1024,1) mb FROM gv$process ORDER BY pga_alloc_mem DESC FETCH FIRST 15 ROWS ONLY;
SELECT sql_id, operation_type, ROUND(actual_mem_used/1024/1024,1) mb, number_passes FROM gv$sql_workarea_active;

PROMPT
PROMPT === End of query: ORA-04030 PGA / process memory — queries ===
PROMPT

-- End of file
