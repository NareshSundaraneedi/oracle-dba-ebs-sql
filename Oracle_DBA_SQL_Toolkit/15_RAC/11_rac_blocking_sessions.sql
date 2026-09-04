--------------------------------------------------------------------------------
-- File Name       : 11_rac_blocking_sessions.sql
-- Category        : 15_RAC
-- Purpose         : Pointer to RAC lock script plus local check
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Re-exports the essential RAC blocking query so RAC on-call does not leave this folder. Full notes in 10/12.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Cross-instance blockers
--------------------------------------------------------------------------------
-- 1. What the query does
--    blocking_instance <> inst_id.
-- 2. Important columns
--    WAITER_INST, BLOCKER_INST.
-- 3. How to interpret the output
--    Root blocker instance is where you generate KILL @inst.
-- 4. What indicates a problem
--    Cross-instance chain during peak.
-- 5. Recommended DBA action
--    10_Locks_Blocking/12.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT w.inst_id waiter_inst, w.sid waiter, w.event, w.seconds_in_wait,
       w.blocking_instance, w.blocking_session, b.username, b.status, b.module
FROM gv$session w
JOIN gv$session b ON b.inst_id=w.blocking_instance AND b.sid=w.blocking_session
WHERE w.blocking_session IS NOT NULL
ORDER BY w.seconds_in_wait DESC;

PROMPT
PROMPT === End of query: Cross-instance blockers ===
PROMPT

-- End of file
