--------------------------------------------------------------------------------
-- File Name       : 03_transport_status.sql
-- Category        : 17_DataGuard
-- Purpose         : Redo transport (LNS/ARCH) health
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$MANAGED_STANDBY / dest status on primary.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Transport dests
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$ARCHIVE_DEST_STATUS type PHYSICAL.
-- 2. Important columns
--    STATUS, GAP_STATUS, SYNCHRONIZATION_STATUS.
-- 3. How to interpret the output
--    RESYNCHRONIZING after a gap.
-- 4. What indicates a problem
--    TRANSPORT-OFF / ERROR.
-- 5. Recommended DBA action
--    Network, dest space, TNS. Alert log on both sides.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVE_DEST_STATUS
--------------------------------------------------------------------------------
SELECT dest_id, status, type, database_mode, recovery_mode, destination,
       gap_status, error, synchronization_status, synchronized
FROM v$archive_dest_status WHERE type <> 'LOCAL' OR dest_id > 1;

PROMPT
PROMPT === End of query: Transport dests ===
PROMPT

-- End of file
