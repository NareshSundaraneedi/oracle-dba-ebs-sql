--------------------------------------------------------------------------------
-- File Name       : 15_sql_child_cursors.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Child cursor explosion and reason codes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Too many child cursors waste shared pool and cause hard parse /
-- mutex waits. V$SQL_SHARED_CURSOR shows why children were not shared.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL with many children and mismatch reasons
--------------------------------------------------------------------------------
-- 1. What the query does
--    Counts children in GV$SQL and samples V$SQL_SHARED_CURSOR.
-- 2. Important columns
--    SQL_ID, CHILDREN, REASON FLAGS.
-- 3. How to interpret the output
--    BIND_MISMATCH, AUTH_CHECK_MISMATCH, OPTIMIZER_MISMATCH are common. EBS NLS differences also split cursors.
-- 4. What indicates a problem
--    Hundreds of children for one SQL_ID plus 'cursor: pin S wait on X'.
-- 5. Recommended DBA action
--    Fix the mismatch (binds, NLS, optimizer settings). Do not flush shared pool in production as a habit.
-- 6. Production cautions
--    Safe. V$SQL_SHARED_CURSOR can be wide — select known reason columns.
-- 7. Required privileges
--    SELECT on GV_$SQL, V_$SQL_SHARED_CURSOR
--------------------------------------------------------------------------------
SELECT sql_id, COUNT(*) children, COUNT(DISTINCT plan_hash_value) plans,
       SUM(parse_calls) parse_calls, ROUND(SUM(sharable_mem)/1024/1024,1) sharable_mb
FROM   gv$sql
GROUP BY sql_id
HAVING COUNT(*) > 20
ORDER BY children DESC
FETCH FIRST 30 ROWS ONLY;

SELECT
       sql_id,
       child_number,
       bind_mismatch,
       optimizer_mismatch,
       auth_check_mismatch,
       language_mismatch,
       outline_mismatch,
       translation_mismatch,
       row_level_sec_mismatch
FROM   v$sql_shared_cursor
WHERE  sql_id = '&sql_id';

PROMPT
PROMPT === End of query: SQL with many children and mismatch reasons ===
PROMPT

-- End of file
