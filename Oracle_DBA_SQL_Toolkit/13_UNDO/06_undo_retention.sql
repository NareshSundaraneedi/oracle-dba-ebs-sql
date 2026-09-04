--------------------------------------------------------------------------------
-- File Name       : 06_undo_retention.sql
-- Category        : 13_UNDO
-- Purpose         : undo_retention vs tuned retention vs guarantee
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- If tuned << configured, you are not achieving the retention because of space.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Retention comparison
--------------------------------------------------------------------------------
-- 1. What the query does
--    Parameter + V$UNDOSTAT tuned.
-- 2. Important columns
--    UNDO_RETENTION, TUNED, RETENTION clause.
-- 3. How to interpret the output
--    Need retention >= longest query/flashback + margin.
-- 4. What indicates a problem
--    Tuned collapsing below the longest concurrent program.
-- 5. Recommended DBA action
--    Add space first, then raise undo_retention.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$UNDOSTAT, DBA_TABLESPACES
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter WHERE name LIKE 'undo%';
SELECT tablespace_name, retention FROM dba_tablespaces WHERE contents='UNDO';
SELECT MAX(tuned_undoretention) max_tuned, MIN(tuned_undoretention) min_tuned,
       MAX(maxquerylen) max_q
FROM v$undostat WHERE begin_time > SYSDATE-1;

PROMPT
PROMPT === End of query: Retention comparison ===
PROMPT

-- End of file
