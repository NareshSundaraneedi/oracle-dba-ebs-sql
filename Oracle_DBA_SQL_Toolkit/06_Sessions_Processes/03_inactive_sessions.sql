--------------------------------------------------------------------------------
-- File Name       : 03_inactive_sessions.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : INACTIVE sessions and how long they have been idle
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- INACTIVE Forms/Java sessions holding locks are a classic EBS
-- issue (user left a form open). LAST_CALL_ET is seconds since last call.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Idle user sessions
--------------------------------------------------------------------------------
-- 1. What the query does
--    STATUS=INACTIVE user sessions ordered by idle time.
-- 2. Important columns
--    SID, USERNAME, LAST_CALL_ET, MODULE, MACHINE.
-- 3. How to interpret the output
--    LAST_CALL_ET of many hours plus a lock (see 10) means a forgotten form.
-- 4. What indicates a problem
--    Inactive session blocking others (blocking_session points here from active waiters).
-- 5. Recommended DBA action
--    Contact the user. Generate disconnect if policy allows — 17_generate_disconnect_session.sql.
-- 6. Production cautions
--    Safe. Killing inactive sessions drops unsaved Forms work.
-- 7. Required privileges
--    SELECT on GV_$SESSION
-- EBS relevance  : Critical for EBS
--------------------------------------------------------------------------------
SELECT
       inst_id,
       sid,
       serial#,
       username,
       osuser,
       machine,
       program,
       module,
       status,
       last_call_et,
       ROUND(last_call_et/3600,2) AS idle_hours,
       logon_time,
       sql_id
FROM   gv$session
WHERE  status = 'INACTIVE'
AND    type   = 'USER'
ORDER BY last_call_et DESC;

PROMPT
PROMPT === End of query: Idle user sessions ===
PROMPT

-- End of file
