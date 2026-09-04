--------------------------------------------------------------------------------
-- File Name       : 07_ora_01555_snapshot_too_old.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-01555 snapshot too old
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: long query/export fails 01555. Initial: V$UNDOSTAT ssolderrcnt, maxqueryid, long TX, undo space. Evidence: this spool + undo file usage. Causes: small undo, long query, fetch across commits, delayed block cleanout. Fix: add undo space AND shorten the query. Raising undo_retention without space does nothing. Post-fix: ssolderrcnt stays 0 for the same workload.
--
-- Production playbook.  add undo space AND shorten the query. Raising undo_retention without space does nothing.
-- Post-fix: ssolderrcnt stays 0 for the same workload.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-01555 snapshot too old — queries
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
SELECT TO_CHAR(begin_time,'DD-MON HH24:MI') t, ssolderrcnt, nospaceerrcnt, maxquerylen, maxqueryid, tuned_undoretention
FROM v$undostat WHERE begin_time>SYSDATE-1 AND (ssolderrcnt>0 OR maxquerylen>1800) ORDER BY begin_time DESC;
SELECT status, ROUND(SUM(bytes)/1024/1024) mb FROM dba_undo_extents GROUP BY status;
SELECT s.sid, s.module, t.start_date, t.used_ublk FROM gv$transaction t JOIN gv$session s ON s.saddr=t.ses_addr ORDER BY t.start_date;

PROMPT
PROMPT === End of query: ORA-01555 snapshot too old — queries ===
PROMPT

-- End of file
