--------------------------------------------------------------------------------
-- File Name       : 22_cursor_usage.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Open cursors per session vs open_cursors parameter
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ORA-01000 is open cursor leaks (typically Java/Forms).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Open cursors vs limit
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$SYSSTAT opened cursors current and V$OPEN_CURSOR counts.
-- 2. Important columns
--    SID, OPEN_CURSORS, PARAMETER.
-- 3. How to interpret the output
--    A session near open_cursors is about to fail. High cache cursors is OK (session cursor cache).
-- 4. What indicates a problem
--    One APPS session with thousands of open cursors.
-- 5. Recommended DBA action
--    Fix the application leak. Raising open_cursors hides the leak.
-- 6. Production cautions
--    Safe. V$OPEN_CURSOR can be large.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$SESSTAT, GV_$STATNAME, V_$PARAMETER
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter WHERE name IN ('open_cursors','session_cached_cursors');

SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       st.value AS open_cursors
FROM   gv$session s
JOIN   gv$sesstat st ON st.inst_id = s.inst_id AND st.sid = s.sid
JOIN   gv$statname sn ON sn.inst_id = st.inst_id AND sn.statistic# = st.statistic#
WHERE  sn.name = 'opened cursors current'
ORDER BY st.value DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Open cursors vs limit ===
PROMPT

-- End of file
