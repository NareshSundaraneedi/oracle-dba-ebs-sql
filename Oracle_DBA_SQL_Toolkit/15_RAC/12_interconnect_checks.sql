--------------------------------------------------------------------------------
-- File Name       : 12_interconnect_checks.sql
-- Category        : 15_RAC
-- Purpose         : Interconnect devices and GC lost blocks
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SQL cannot ping the interconnect. This shows what Oracle thinks the interconnect is and lost-block stats.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Cluster interconnects and losts
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$CLUSTER_INTERCONNECTS / GV$CONFIGURED_INTERCONNECTS + lost stats.
-- 2. Important columns
--    IP_ADDRESS, IS_PUBLIC, LOST.
-- 3. How to interpret the output
--    IS_PUBLIC TRUE on the interconnect is a serious misconfig.
-- 4. What indicates a problem
--    Lost blocks > 0 or public interconnect.
-- 5. Recommended DBA action
--    Fix HAIP/cluster_interconnects with the sysadmin. Bounce may be required.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$CLUSTER_INTERCONNECTS, GV_$CONFIGURED_INTERCONNECTS, GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT inst_id, name, ip_address, is_public FROM gv$configured_interconnects;
SELECT inst_id, name, ip_address FROM gv$cluster_interconnects;
SELECT inst_id, name, value FROM gv$sysstat WHERE name IN ('gc blocks lost','gc cr blocks lost','gc current blocks lost');

PROMPT
PROMPT === End of query: Cluster interconnects and losts ===
PROMPT

-- End of file
