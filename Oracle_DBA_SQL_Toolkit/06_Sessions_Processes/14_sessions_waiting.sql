--------------------------------------------------------------------------------
-- File Name       : 14_sessions_waiting.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Active sessions currently waiting (non-idle)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Wait-class filtered view. Idle wait classes are excluded so you
-- see real stalls.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Non-idle waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SESSION where WAIT_CLASS <> Idle and STATUS ACTIVE.
-- 2. Important columns
--    EVENT, WAIT_CLASS, SECONDS_IN_WAIT, SQL_ID, BLOCKING_SESSION.
-- 3. How to interpret the output
--    WAIT_CLASS Concurrency / Application / Commit / User I/O drive the next script you open.
-- 4. What indicates a problem
--    Many waiters, one BLOCKING_SESSION.
-- 5. Recommended DBA action
--    10_Locks_Blocking if Application/Concurrency; 09_Wait_Events otherwise.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       inst_id,
       sid,
       serial#,
       username,
       module,
       sql_id,
       event,
       wait_class,
       state,
       seconds_in_wait,
       blocking_session,
       blocking_instance,
       p1text, p1, p2text, p2, p3text, p3
FROM   gv$session
WHERE  status = 'ACTIVE'
AND    wait_class <> 'Idle'
ORDER BY wait_class, event, seconds_in_wait DESC;

PROMPT
PROMPT === End of query: Non-idle waiters ===
PROMPT

-- End of file
