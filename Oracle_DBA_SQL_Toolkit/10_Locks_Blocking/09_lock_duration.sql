--------------------------------------------------------------------------------
-- File Name       : 09_lock_duration.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : How long locks have been held (V$LOCK.CTIME)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- CTIME is seconds since the lock was taken. Long CTIME on a
-- TX lock is an uncommitted transaction.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Long-held locks
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$LOCK ordered by CTIME for TX/TM.
-- 2. Important columns
--    SID, TYPE, LMODE, CTIME, USERNAME.
-- 3. How to interpret the output
--    CTIME 20000s = ~5.5 hours uncommitted.
-- 4. What indicates a problem
--    Long TX during high concurrency.
-- 5. Recommended DBA action
--    Find the session (STATUS, MODULE). Ask for commit/rollback or disconnect POST_TRANSACTION.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$LOCK, GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       l.inst_id,
       l.sid,
       s.serial#,
       s.username,
       s.status,
       s.module,
       s.machine,
       l.type,
       l.lmode,
       l.request,
       l.ctime AS seconds_held,
       ROUND(l.ctime/60,1) AS minutes_held,
       s.sql_id
FROM   gv$lock l
JOIN   gv$session s ON s.inst_id = l.inst_id AND s.sid = l.sid
WHERE  l.type IN ('TX','TM','UL')
AND    l.lmode > 0
ORDER BY l.ctime DESC
FETCH FIRST 50 ROWS ONLY;

PROMPT
PROMPT === End of query: Long-held locks ===
PROMPT

-- End of file
