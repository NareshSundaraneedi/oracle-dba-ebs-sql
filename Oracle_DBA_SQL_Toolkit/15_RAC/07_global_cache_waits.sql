--------------------------------------------------------------------------------
-- File Name       : 07_global_cache_waits.sql
-- Category        : 15_RAC
-- Purpose         : Global cache wait summary
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Cluster wait class rollup. See 09/10-11 for event meaning.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Cluster waits per instance
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SYSTEM_EVENT wait_class Cluster.
-- 2. Important columns
--    EVENT, TIME_S, INST.
-- 3. How to interpret the output
--    Compare instances — one congested node.
-- 4. What indicates a problem
--    gc buffer busy / congested high.
-- 5. Recommended DBA action
--    Interconnect + hot blocks.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, event, ROUND(time_waited_micro/1e6,1) time_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM gv$system_event WHERE wait_class='Cluster'
ORDER BY time_s DESC;

PROMPT
PROMPT === End of query: Cluster waits per instance ===
PROMPT

-- End of file
