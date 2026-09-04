--------------------------------------------------------------------------------
-- File Name       : 07_archive_log_status.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Recent archived logs and completion
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ARCHIVED_LOG for last-day inventory.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Recent archived logs
--------------------------------------------------------------------------------
-- 1. What the query does
--    Last 24h logs.
-- 2. Important columns
--    SEQUENCE#, FIRST_TIME, NEXT_TIME, DELETED, STANDBY.
-- 3. How to interpret the output
--    DELETED YES means RMAN already removed them (need backups).
-- 4. What indicates a problem
--    Gap in sequence numbers.
-- 5. Recommended DBA action
--    17_DataGuard archive gap if standby.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVED_LOG
--------------------------------------------------------------------------------
SELECT thread#, sequence#, dest_id,
       TO_CHAR(first_time,'DD-MON HH24:MI:SS') first_time,
       TO_CHAR(completion_time,'DD-MON HH24:MI:SS') completed,
       ROUND(blocks*block_size/1024/1024,1) mb,
       deleted, status, standby_dest
FROM v$archived_log
WHERE first_time > SYSDATE-1
ORDER BY thread#, sequence#, dest_id;

PROMPT
PROMPT === End of query: Recent archived logs ===
PROMPT

-- End of file
