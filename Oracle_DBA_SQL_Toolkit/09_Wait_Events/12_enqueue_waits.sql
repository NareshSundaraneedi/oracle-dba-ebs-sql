--------------------------------------------------------------------------------
-- File Name       : 12_enqueue_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Enqueue (enq:) waits
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: enqueues are locks (TX, TM, SQ, HW, ST, CF, ...).
-- Cause: row locks, table locks, sequence, high water mark, space.
-- Investigate: event name → 10_Locks; SQ → sequence cache; HW → mass insert.
-- Fix: commit design, indexes on FK, sequence cache, don't use LOCK TABLE.
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
-- QUERY 1: Enqueue events
--------------------------------------------------------------------------------
-- 1. What the query does
--    Events like enq:% from system and current sessions.
-- 2. Important columns
--    EVENT, TIME_S, CURRENT WAITERS.
-- 3. How to interpret the output
--    TX row lock contention is application locking. TM contention is often unindexed FK.
-- 4. What indicates a problem
--    enq: TX #1 during a Forms-heavy period.
-- 5. Recommended DBA action
--    10_Locks_Blocking.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SESSION
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  event LIKE 'enq:%'
ORDER BY time_waited_micro DESC;

SELECT inst_id, sid, username, event, seconds_in_wait, blocking_session, sql_id, module
FROM   gv$session
WHERE  event LIKE 'enq:%'
ORDER BY seconds_in_wait DESC;

PROMPT
PROMPT === End of query: Enqueue events ===
PROMPT

-- End of file
