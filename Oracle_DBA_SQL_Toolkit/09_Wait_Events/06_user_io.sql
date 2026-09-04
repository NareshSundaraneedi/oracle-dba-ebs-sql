--------------------------------------------------------------------------------
-- File Name       : 06_user_io.sql
-- Category        : 09_Wait_Events
-- Purpose         : Foreground User I/O only
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 05: excludes DBWR/LGWR System I/O so you see
-- application read/write waits only.
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
-- QUERY 1: User I/O events
--------------------------------------------------------------------------------
-- 1. What the query does
--    WAIT_CLASS = User I/O.
-- 2. Important columns
--    EVENT, AVG_MS, TIME_S.
-- 3. How to interpret the output
--    sequential read = index/single-block. scattered read = multiblock FTS.
-- 4. What indicates a problem
--    scattered read dominates OLTP hours.
-- 5. Recommended DBA action
--    24_full_table_scans and 15/16 event scripts.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'User I/O'
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: User I/O events ===
PROMPT

-- End of file
