--------------------------------------------------------------------------------
-- File Name       : 04_long_running_sessions.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Active sessions with LAST_CALL_ET over a threshold
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds database calls that have been running longer than &min_seconds.
-- For EBS concurrent requests, also use folder 22 — this script is instance-level.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Long-running active calls
--------------------------------------------------------------------------------
-- 1. What the query does
--    ACTIVE sessions with LAST_CALL_ET >= &min_seconds.
-- 2. Important columns
--    SID, SQL_ID, LAST_CALL_ET, EVENT, MODULE.
-- 3. How to interpret the output
--    LAST_CALL_ET is the current call duration, not the session age.
-- 4. What indicates a problem
--    A session running 8 hours on a form SQL during business hours.
-- 5. Recommended DBA action
--    Get SQL_ID, plan, waits (08_SQL_Tuning / 25_EBS troubleshooting).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$SQL
--------------------------------------------------------------------------------
DEFINE min_seconds = 600

SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       s.action,
       s.program,
       s.sql_id,
       s.event,
       s.last_call_et,
       ROUND(s.last_call_et/60,1) AS minutes_running,
       q.sql_text
FROM   gv$session s
LEFT JOIN gv$sql q
       ON q.inst_id = s.inst_id AND q.sql_id = s.sql_id AND q.child_number = s.sql_child_number
WHERE  s.status = 'ACTIVE'
AND    s.type   = 'USER'
AND    s.last_call_et >= &min_seconds
ORDER BY s.last_call_et DESC;

PROMPT
PROMPT === End of query: Long-running active calls ===
PROMPT

-- End of file
