--------------------------------------------------------------------------------
-- File Name       : 11_rfs_status.sql
-- Category        : 17_DataGuard
-- Purpose         : RFS processes (standby receivers)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- RFS receives redo from primary LNS/ARCH.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: RFS
--------------------------------------------------------------------------------
-- 1. What the query does
--    PROCESS LIKE RFS%.
-- 2. Important columns
--    STATUS, SEQUENCE#.
-- 3. How to interpret the output
--    No RFS on standby while primary thinks it ships → network/listener.
-- 4. What indicates a problem
--    RFS idle and transport lag growing.
-- 5. Recommended DBA action
--    Listener, TNS, firewall, password file.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$MANAGED_STANDBY
--------------------------------------------------------------------------------
SELECT process, status, thread#, sequence#, block#, client_process, client_pid
FROM v$managed_standby WHERE process LIKE 'RFS%';

PROMPT
PROMPT === End of query: RFS ===
PROMPT

-- End of file
