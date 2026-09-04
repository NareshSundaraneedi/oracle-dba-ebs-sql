--------------------------------------------------------------------------------
-- File Name       : 11_rac_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Detailed RAC/global cache wait names
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: gc cr request = consistent read block needed from another inst.
-- gc current request = current mode (DML).
-- Cause: same block modified on multiple nodes (hot block, sequence, index leaf).
-- Investigate: V$INSTANCE_CACHE_TRANSFER, ASH p1 file/block.
-- Fix: partition, reverse key (careful), pin service to one node, increase sequence cache.
--
-- RAC where applicable.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: GC events and cache transfers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Cluster events plus GV$INSTANCE_CACHE_TRANSFER.
-- 2. Important columns
--    EVENT, CR_BLOCKS, CURRENT_BLOCKS.
-- 3. How to interpret the output
--    High current transfers on one object = DML ping-pong.
-- 4. What indicates a problem
--    Lost blocks / congested on interconnect stats (15_RAC).
-- 5. Recommended DBA action
--    15_RAC/07-12.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$INSTANCE_CACHE_TRANSFER
--
-- RAC where applicable.
--------------------------------------------------------------------------------
SELECT inst_id, event,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event LIKE 'gc %'
ORDER BY time_waited_micro DESC;

SELECT instance, cr_block, current_block, lost, congested
FROM   gv$instance_cache_transfer
ORDER BY instance;

PROMPT
PROMPT === End of query: GC events and cache transfers ===
PROMPT

-- End of file
