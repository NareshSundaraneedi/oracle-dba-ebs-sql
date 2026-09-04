--------------------------------------------------------------------------------
-- File Name       : 02_session_wait_events.sql
-- Category        : 09_Wait_Events
-- Purpose         : Per-session wait totals (V$SESSION_EVENT)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Cumulative waits per session lifetime. Useful for a long-running
-- session; not for 'now' (use V$SESSION / ASH).
--
-- Pack-free.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Session events for one SID or top waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$SESSION_EVENT joined to sessions.
-- 2. Important columns
--    SID, EVENT, TIME_WAITED_S.
-- 3. How to interpret the output
--    A session that lived for days accumulates everything — filter by current SQL.
-- 4. What indicates a problem
--    One session with hours on enq: TX.
-- 5. Recommended DBA action
--    10_Locks_Blocking.
-- 6. Production cautions
--    Safe. Specify SID when possible.
-- 7. Required privileges
--    SELECT on GV_$SESSION_EVENT, GV_$SESSION
--------------------------------------------------------------------------------
DEFINE sid_p = 0

SELECT
       e.inst_id,
       e.sid,
       s.username,
       s.sql_id,
       e.event,
       e.wait_class,
       e.total_waits,
       ROUND(e.time_waited_micro/1e6,1) AS time_waited_s
FROM   gv$session_event e
JOIN   gv$session s ON s.inst_id = e.inst_id AND s.sid = e.sid
WHERE  e.wait_class <> 'Idle'
AND    ( &sid_p = 0 OR e.sid = &sid_p )
ORDER BY e.time_waited_micro DESC
FETCH FIRST 50 ROWS ONLY;

PROMPT
PROMPT === End of query: Session events for one SID or top waiters ===
PROMPT

-- End of file
