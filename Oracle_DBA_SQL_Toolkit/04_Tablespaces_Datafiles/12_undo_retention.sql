--------------------------------------------------------------------------------
-- File Name       : 12_undo_retention.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Show undo_retention vs tuned retention
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- TUNED_UNDORETENTION in V$UNDOSTAT is what the instance is actually
-- achieving. If it is far below undo_retention, space is insufficient.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Configured vs tuned undo retention
--------------------------------------------------------------------------------
-- 1. What the query does
--    Compares parameter undo_retention to V$UNDOSTAT.TUNED_UNDORETENTION.
-- 2. Important columns
--    UNDO_RETENTION, TUNED_UNDORETENTION, SSOLDERRCNT.
-- 3. How to interpret the output
--    SSOLDERRCNT > 0 in recent intervals means ORA-01555 occurred.
-- 4. What indicates a problem
--    Tuned retention collapsing during the day while a 3-hour report runs.
-- 5. Recommended DBA action
--    Increase undo datafile size before raising undo_retention. See 13_UNDO/07.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$UNDOSTAT
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter
WHERE  name IN ('undo_retention','undo_tablespace','undo_management');

SELECT
       TO_CHAR(begin_time,'DD-MON HH24:MI') begin_time,
       tuned_undoretention,
       maxquerylen,
       ssolderrcnt,
       nospaceerrcnt,
       undoblks
FROM   v$undostat
WHERE  begin_time > SYSDATE - 1
ORDER BY begin_time DESC;

PROMPT
PROMPT === End of query: Configured vs tuned undo retention ===
PROMPT

-- End of file
