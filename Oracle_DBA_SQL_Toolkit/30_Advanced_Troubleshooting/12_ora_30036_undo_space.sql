--------------------------------------------------------------------------------
-- File Name       : 12_ora_30036_undo_space.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-30036 unable to extend undo
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: DML cannot get undo extent. Initial: undo files, expired vs active, long TX, retention guarantee. Evidence: 13_UNDO scripts. Causes: huge transaction, small undo, guarantee + retention too high. Fix: add undo file; commit/rollback the hog; do not shrink undo during the error. Post-fix: nospaceerrcnt 0; DML succeeds.
--
-- Production playbook.  add undo file; commit/rollback the hog; do not shrink undo during the error.
-- Post-fix: nospaceerrcnt 0; DML succeeds.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-30036 unable to extend undo — queries
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
SELECT tablespace_name, status, ROUND(SUM(bytes)/1024/1024) mb FROM dba_undo_extents GROUP BY tablespace_name, status;
SELECT name, value FROM v$parameter WHERE name LIKE 'undo%';
SELECT s.sid, s.module, t.used_ublk, t.start_date FROM gv$transaction t JOIN gv$session s ON s.saddr=t.ses_addr ORDER BY t.used_ublk DESC;

PROMPT
PROMPT === End of query: ORA-30036 unable to extend undo — queries ===
PROMPT

-- End of file
