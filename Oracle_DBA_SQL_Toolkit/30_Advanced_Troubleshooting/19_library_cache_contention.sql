--------------------------------------------------------------------------------
-- File Name       : 19_library_cache_contention.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : Library cache / cursor pin contention
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: cursor: pin S wait on X, library cache lock. Initial: hard parse ratio, children per SQL, who is compiling, recent flush/stats. Evidence: 07/15, 17, 23. Causes: literal SQL, mid-day compile, flush, invalidations. Fix: stop compiles/flush; share SQL. Do not flush to fix this. Post-fix: parse waits gone; hard parse ratio normal.
--
-- Production playbook.  stop compiles/flush; share SQL. Do not flush to fix this.
-- Post-fix: parse waits gone; hard parse ratio normal.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Library cache / cursor pin contention — queries
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
SELECT event, COUNT(*) FROM gv$session WHERE event LIKE 'library cache%' OR event LIKE 'cursor: pin%' GROUP BY event;
SELECT sql_id, COUNT(*) FROM gv$sql GROUP BY sql_id HAVING COUNT(*)>30 ORDER BY 2 DESC FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT === End of query: Library cache / cursor pin contention — queries ===
PROMPT

-- End of file
