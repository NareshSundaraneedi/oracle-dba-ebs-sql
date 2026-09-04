--------------------------------------------------------------------------------
-- File Name       : 14_ora_00054_resource_busy.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-00054 resource busy (DDL / lock)
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: DDL or LOCK TABLE fails 00054. Initial: who locks the object (10/07), TM locks. Evidence: V$LOCKED_OBJECT for that object. Causes: long transaction, forgotten form, online redef leftover. Fix: wait or disconnect blocker POST_TRANSACTION. Do not bounce. Post-fix: DDL succeeds in the window.
--
-- Production playbook.  wait or disconnect blocker POST_TRANSACTION. Do not bounce.
-- Post-fix: DDL succeeds in the window.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-00054 resource busy (DDL / lock) — queries
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
SELECT lo.session_id, s.serial#, s.status, s.module, s.event, o.object_name, lo.locked_mode
FROM gv$locked_object lo JOIN dba_objects o ON o.object_id=lo.object_id
JOIN gv$session s ON s.inst_id=lo.inst_id AND s.sid=lo.session_id
ORDER BY o.object_name;

PROMPT
PROMPT === End of query: ORA-00054 resource busy (DDL / lock) — queries ===
PROMPT

-- End of file
