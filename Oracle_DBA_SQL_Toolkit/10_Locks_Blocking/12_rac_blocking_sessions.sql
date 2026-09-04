--------------------------------------------------------------------------------
-- File Name       : 12_rac_blocking_sessions.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : Cross-instance blocking on RAC (including global locks)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- On RAC a waiter on node 2 may be blocked by node 1. Also check
-- gv$ges_blocking_enqueue for global enqueue details.
--
-- RAC where applicable. BLOCKING_INSTANCE is required — never assume the blocker is local.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: RAC cross-instance blockers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Highlights blocking_instance <> waiter inst_id and GES view if available.
-- 2. Important columns
--    WAITER_INST, BLOCKER_INST, EVENT, SID.
-- 3. How to interpret the output
--    Cross-instance TX is still a row lock; just the holder is remote.
-- 4. What indicates a problem
--    All waiters on node 2, blocker on node 1 — still kill/disconnect the root on node 1.
-- 5. Recommended DBA action
--    Use KILL SESSION 'sid,serial#,@inst'.
-- 6. Production cautions
--    Safe. gv$ges_blocking_enqueue may be empty if no global enqueue wait.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$GES_BLOCKING_ENQUEUE
--
-- RAC where applicable.
--------------------------------------------------------------------------------
SELECT
       w.inst_id waiter_inst,
       w.sid waiter_sid,
       w.event,
       w.sql_id,
       w.seconds_in_wait,
       w.blocking_instance,
       w.blocking_session,
       b.username blocker_user,
       b.status blocker_status,
       b.module blocker_module,
       b.machine
FROM   gv$session w
JOIN   gv$session b
       ON b.inst_id = w.blocking_instance
      AND b.sid     = w.blocking_session
WHERE  w.blocking_session IS NOT NULL
ORDER BY CASE WHEN w.inst_id <> w.blocking_instance THEN 0 ELSE 1 END,
         w.seconds_in_wait DESC;

SELECT * FROM gv$ges_blocking_enqueue;

PROMPT
PROMPT === End of query: RAC cross-instance blockers ===
PROMPT

-- End of file
