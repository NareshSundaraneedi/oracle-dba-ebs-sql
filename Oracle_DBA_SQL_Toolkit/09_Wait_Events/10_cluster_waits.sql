--------------------------------------------------------------------------------
-- File Name       : 10_cluster_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Cluster wait class (RAC global cache)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: time waiting for another instance to send a block.
-- Cause: chatty blocks across RAC, poor interconnect, imbalance, sequence.
-- Investigate: 11_rac_waits and folder 15.
-- Fix: localize the workload, faster interconnect, reduce block ping — not more SGA first.
--
-- RAC where applicable. Pack-free for V$SYSTEM_EVENT.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Cluster class events
--------------------------------------------------------------------------------
-- 1. What the query does
--    WAIT_CLASS = Cluster.
-- 2. Important columns
--    EVENT, TIME_S, AVG_MS.
-- 3. How to interpret the output
--    gc cr/current multi block / grant 2-way / 3-way breakdown matters.
-- 4. What indicates a problem
--    Cluster class #1 after a node eviction or interconnect packet loss.
-- 5. Recommended DBA action
--    15_RAC interconnect + service placement.
-- 6. Production cautions
--    Safe. Empty on single instance.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--
-- RAC where applicable.
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'Cluster'
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: Cluster class events ===
PROMPT

-- End of file
