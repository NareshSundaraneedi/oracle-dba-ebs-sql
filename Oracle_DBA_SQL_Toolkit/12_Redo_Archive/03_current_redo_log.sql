--------------------------------------------------------------------------------
-- File Name       : 03_current_redo_log.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Which redo group is CURRENT per thread
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Quick check during log switch problems.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: CURRENT logs
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$LOG STATUS=CURRENT.
-- 2. Important columns
--    GROUP#, SEQUENCE#, FIRST_TIME.
-- 3. How to interpret the output
--    Sequence should be advancing. Stuck sequence = archiver or checkpoint hang.
-- 4. What indicates a problem
--    CURRENT group not changing for a long time on a busy DB (or changing every second).
-- 5. Recommended DBA action
--    12/11 log switches + archiver.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$LOG
--------------------------------------------------------------------------------
SELECT thread#, group#, sequence#, ROUND(bytes/1024/1024) mb, status, first_time
FROM v$log WHERE status = 'CURRENT' ORDER BY thread#;

PROMPT
PROMPT === End of query: CURRENT logs ===
PROMPT

-- End of file
