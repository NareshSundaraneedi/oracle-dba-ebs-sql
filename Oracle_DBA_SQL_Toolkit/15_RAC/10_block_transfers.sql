--------------------------------------------------------------------------------
-- File Name       : 10_block_transfers.sql
-- Category        : 15_RAC
-- Purpose         : Cache transfer counts between instances
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- GV$INSTANCE_CACHE_TRANSFER / GV$GC_ELEMENT style counts.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Transfers
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$INSTANCE_CACHE_TRANSFER.
-- 2. Important columns
--    INSTANCE, CR_BLOCK, CURRENT_BLOCK, LOST, CONGESTED.
-- 3. How to interpret the output
--    LOST > 0 is interconnect packet loss — OS/network priority.
-- 4. What indicates a problem
--    LOST or CONGESTED climbing.
-- 5. Recommended DBA action
--    Netadmin + Jumbo frames/RDS review. Not an SQL tune first.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$INSTANCE_CACHE_TRANSFER
--------------------------------------------------------------------------------
SELECT inst_id, instance, cr_block, current_block, data_request, lost, congested
FROM gv$instance_cache_transfer ORDER BY inst_id, instance;

PROMPT
PROMPT === End of query: Transfers ===
PROMPT

-- End of file
