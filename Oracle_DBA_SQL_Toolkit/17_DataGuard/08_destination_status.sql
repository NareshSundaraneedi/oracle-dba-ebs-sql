--------------------------------------------------------------------------------
-- File Name       : 08_destination_status.sql
-- Category        : 17_DataGuard
-- Purpose         : All dests including local
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Full dest picture for the primary.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Dest status
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$ARCHIVE_DEST_STATUS.
-- 2. Important columns
--    DEST_ID, STATUS, ERROR.
-- 3. How to interpret the output
--    VALID + SYNCHRONIZED YES for SYNC dests.
-- 4. What indicates a problem
--    ERROR on remote dest.
-- 5. Recommended DBA action
--    12/09 + broker show database.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVE_DEST_STATUS
--------------------------------------------------------------------------------
SELECT dest_id, dest_name, status, type, database_mode, recovery_mode,
       destination, error, gap_status, synchronized
FROM v$archive_dest_status ORDER BY dest_id;

PROMPT
PROMPT === End of query: Dest status ===
PROMPT

-- End of file
