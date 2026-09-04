--------------------------------------------------------------------------------
-- File Name       : 06_archive_destination.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Archive destinations configuration
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ARCHIVE_DEST shows local/remote dests including Data Guard.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$ARCHIVE_DEST
--------------------------------------------------------------------------------
-- 1. What the query does
--    Destinations and errors.
-- 2. Important columns
--    DEST_ID, STATUS, DESTINATION, ERROR, VALID_TYPE.
-- 3. How to interpret the output
--    STATUS ERROR with a remote dest can stall the primary if LGWR SYNC.
-- 4. What indicates a problem
--    Local dest VALID but ERROR text populated.
-- 5. Recommended DBA action
--    Fix space/network. Defer dest only with DG awareness.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVE_DEST
--------------------------------------------------------------------------------
SELECT dest_id, status, target, destination, valid_type, valid_role, db_unique_name, error
FROM v$archive_dest WHERE status <> 'INACTIVE' ORDER BY dest_id;

PROMPT
PROMPT === End of query: V$ARCHIVE_DEST ===
PROMPT

-- End of file
