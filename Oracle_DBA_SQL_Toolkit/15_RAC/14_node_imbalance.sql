--------------------------------------------------------------------------------
-- File Name       : 14_node_imbalance.sql
-- Category        : 15_RAC
-- Purpose         : Combined imbalance score (sessions, DB time, GC)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- One-page RAC imbalance for the bridge.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Imbalance snapshot
--------------------------------------------------------------------------------
-- 1. What the query does
--    Side-by-side inst metrics.
-- 2. Important columns
--    SESSIONS, DB_TIME, GC_TIME.
-- 3. How to interpret the output
--    Investigate if one node has most DB time and most GC — might be the writer node.
-- 4. What indicates a problem
--    One node CPU 100%, the other idle, after a node crash.
-- 5. Recommended DBA action
--    Check services, job class instance affinity, and TAF.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$SYS_TIME_MODEL, GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, COUNT(*) sessions FROM gv$session GROUP BY inst_id;
SELECT inst_id, ROUND(value/1e6,1) db_time_s FROM gv$sys_time_model WHERE stat_name='DB time';
SELECT inst_id, ROUND(SUM(time_waited_micro)/1e6,1) cluster_wait_s
FROM gv$system_event WHERE wait_class='Cluster' GROUP BY inst_id;

PROMPT
PROMPT === End of query: Imbalance snapshot ===
PROMPT

-- End of file
