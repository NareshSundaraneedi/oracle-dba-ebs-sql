--------------------------------------------------------------------------------
-- File Name       : 05_ora_01555_investigation.sql
-- Category        : 13_UNDO
-- Purpose         : Snapshot too old evidence (V$UNDOSTAT SSOLDERRCNT)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: ORA-01555. This file gathers evidence. Full playbook: 30/07.
--
-- Playbook structure in 30_Advanced_Troubleshooting/07_ora_01555_snapshot_too_old.sql
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SSOLDERRCNT and longest query
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$UNDOSTAT.
-- 2. Important columns
--    SSOLDERRCNT, MAXQUERYLEN, MAXQUERYID.
-- 3. How to interpret the output
--    MAXQUERYID is the long query that needed undo (victim or cause).
-- 4. What indicates a problem
--    SSOLDERRCNT > 0 in the incident window.
-- 5. Recommended DBA action
--    Increase undo space/retention AND tune/schedule the long query. Killing others may not help.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$UNDOSTAT
--------------------------------------------------------------------------------
SELECT TO_CHAR(begin_time,'DD-MON HH24:MI') begin_time,
       undoblks, txncount, maxquerylen, maxqueryid,
       tuned_undoretention, ssolderrcnt, nospaceerrcnt
FROM v$undostat WHERE begin_time > SYSDATE-2
AND (ssolderrcnt>0 OR nospaceerrcnt>0 OR maxquerylen>3600)
ORDER BY begin_time DESC;

PROMPT
PROMPT === End of query: SSOLDERRCNT and longest query ===
PROMPT

-- End of file
