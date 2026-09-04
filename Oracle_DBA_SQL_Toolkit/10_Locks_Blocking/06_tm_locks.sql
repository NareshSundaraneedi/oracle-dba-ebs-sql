--------------------------------------------------------------------------------
-- File Name       : 06_tm_locks.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : TM (table) locks — often unindexed FK or explicit LOCK TABLE
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- TM locks block DDL and can queue DML. Identify the object via
-- ID1 (object_id) on the TM lock.
--
-- enq: TM - contention: waiting for a table lock.
-- Common EBS cause: DELETE/UPDATE parent while child FK is unindexed.
-- See 05_Objects/07_foreign_keys.sql.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: TM locks and objects
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins GV$LOCK TYPE=TM to DBA_OBJECTS.
-- 2. Important columns
--    OBJECT_NAME, LMODE, REQUEST, SID, EVENT.
-- 3. How to interpret the output
--    LMODE 3 = row-X (SX) typical DML. REQUEST 5+ is someone wanting a higher table lock (DDL or LOCK TABLE).
-- 4. What indicates a problem
--    A CTAS/DDL waiting behind DML, or parent delete causing TM on child.
-- 5. Recommended DBA action
--    Find unindexed FK. Reschedule DDL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$LOCK, GV_$SESSION, DBA_OBJECTS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       l.inst_id,
       l.sid,
       s.serial#,
       s.username,
       s.event,
       s.sql_id,
       s.module,
       l.lmode,
       l.request,
       l.ctime,
       o.owner,
       o.object_name,
       o.object_type
FROM   gv$lock l
JOIN   gv$session s ON s.inst_id = l.inst_id AND s.sid = l.sid
LEFT JOIN dba_objects o ON o.object_id = l.id1
WHERE  l.type = 'TM'
ORDER BY l.request DESC, l.ctime DESC;

PROMPT
PROMPT === End of query: TM locks and objects ===
PROMPT

-- End of file
