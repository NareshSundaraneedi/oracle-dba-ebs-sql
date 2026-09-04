--------------------------------------------------------------------------------
-- File Name       : 13_library_cache_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Library cache pin/lock/mutex waits
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: waiting to pin or lock a library cache object (SQL, package).
-- Cause: hard parse storm, invalidations, compiling packages, mutex on hot cursor.
-- Investigate: 07/15 child cursors, 17 hard parse, who is compiling.
-- Fix: stop mid-day compiles, share SQL, do not flush shared pool.
-- Possible Fix: increase shared pool only if advice + 4031 evidence supports it.
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
-- QUERY 1: Library cache and mutex events
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters library cache / cursor: pin events.
-- 2. Important columns
--    EVENT, TIME_S, CURRENT SESSIONS.
-- 3. How to interpret the output
--    cursor: pin S wait on X is a hot cursor + parse.
-- 4. What indicates a problem
--    These events #1 after a stats job or FLUSH SHARED_POOL.
-- 5. Recommended DBA action
--    07_Performance_Tuning 15/17/23. 30_Advanced library cache.
-- 6. Production cautions
--    Safe. Do not flush shared pool to 'fix' this.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SESSION
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  event LIKE 'library cache%'
OR     event LIKE 'cursor: pin%'
OR     event LIKE 'kksfbc child completion%'
ORDER BY time_waited_micro DESC;

SELECT inst_id, sid, username, event, sql_id, module, seconds_in_wait
FROM   gv$session
WHERE  event LIKE 'library cache%'
OR     event LIKE 'cursor: pin%';

PROMPT
PROMPT === End of query: Library cache and mutex events ===
PROMPT

-- End of file
