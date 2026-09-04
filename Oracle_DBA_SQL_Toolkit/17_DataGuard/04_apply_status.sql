--------------------------------------------------------------------------------
-- File Name       : 04_apply_status.sql
-- Category        : 17_DataGuard
-- Purpose         : Apply / MRP running?
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- On the standby: V$MANAGED_STANDBY process MRP0.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Managed standby processes
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$MANAGED_STANDBY.
-- 2. Important columns
--    PROCESS, STATUS, SEQUENCE#, BLOCK#.
-- 3. How to interpret the output
--    MRP0 APPLYING_LOG is healthy apply. WAIT_FOR_LOG is idle waiting redo.
-- 4. What indicates a problem
--    No MRP0 process — apply stopped.
-- 5. Recommended DBA action
--    ALTER DATABASE RECOVER MANAGED STANDBY ... is a change; prefer broker: DGMGRL EDIT/START.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on V_$MANAGED_STANDBY
--------------------------------------------------------------------------------
SELECT process, pid, status, thread#, sequence#, block#, blocks, delay_mins
FROM v$managed_standby
ORDER BY process;

PROMPT
PROMPT === End of query: Managed standby processes ===
PROMPT

-- End of file
