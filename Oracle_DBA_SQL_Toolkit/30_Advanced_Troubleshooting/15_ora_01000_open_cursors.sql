--------------------------------------------------------------------------------
-- File Name       : 15_ora_01000_open_cursors.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-01000 maximum open cursors
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: session hits open_cursors. Initial: opened cursors current vs parameter, leaked session. Evidence: V$OPEN_CURSOR for that SID. Causes: Java/Forms leak, missing close, high session_cached_cursors confusion (cache ≠ open leak). Fix: fix the app. Raising open_cursors hides leaks. Post-fix: session cursor count stable.
--
-- Production playbook.  fix the app. Raising open_cursors hides leaks.
-- Post-fix: session cursor count stable.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-01000 maximum open cursors — queries
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
SELECT name, value FROM v$parameter WHERE name IN ('open_cursors','session_cached_cursors');
SELECT s.sid, s.module, st.value open_now
FROM gv$session s JOIN gv$sesstat st ON st.sid=s.sid AND st.inst_id=s.inst_id
JOIN gv$statname sn ON sn.statistic#=st.statistic# AND sn.inst_id=st.inst_id
WHERE sn.name='opened cursors current' ORDER BY st.value DESC FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: ORA-01000 maximum open cursors — queries ===
PROMPT

-- End of file
