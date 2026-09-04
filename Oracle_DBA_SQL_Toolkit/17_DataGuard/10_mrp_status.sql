--------------------------------------------------------------------------------
-- File Name       : 10_mrp_status.sql
-- Category        : 17_DataGuard
-- Purpose         : MRP0 detail
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Apply process only.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: MRP
--------------------------------------------------------------------------------
-- 1. What the query does
--    PROCESS LIKE MRP%.
-- 2. Important columns
--    STATUS, SEQUENCE#.
-- 3. How to interpret the output
--    WAIT_FOR_GAP is a gap. APPLYING_LOG is good.
-- 4. What indicates a problem
--    MRP not present.
-- 5. Recommended DBA action
--    Start apply via DGMGRL: EDIT DATABASE ... SET STATE='APPLY-ON';
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$MANAGED_STANDBY
--------------------------------------------------------------------------------
SELECT process, status, thread#, sequence#, block#, delay_mins, client_pid
FROM v$managed_standby WHERE process LIKE 'MRP%' OR process LIKE 'PR%';

PROMPT
PROMPT === End of query: MRP ===
PROMPT

-- End of file
