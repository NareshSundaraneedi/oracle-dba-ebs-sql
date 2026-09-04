--------------------------------------------------------------------------------
-- File Name       : 08_archive_gap.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Archive gaps (primary view of standby lag files)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ARCHIVE_GAP on the standby shows missing sequences. On primary, compare dest apply.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$ARCHIVE_GAP and dest gap_status
--------------------------------------------------------------------------------
-- 1. What the query does
--    Gap views.
-- 2. Important columns
--    THREAD#, LOW_SEQUENCE#, HIGH_SEQUENCE#.
-- 3. How to interpret the output
--    Any row is a gap that prevents apply.
-- 4. What indicates a problem
--    Gap growing — transport broken.
-- 5. Recommended DBA action
--    17_DataGuard. Restore missing archives from backup.
-- 6. Production cautions
--    Safe. Often empty on primary.
-- 7. Required privileges
--    SELECT on V_$ARCHIVE_GAP, V_$ARCHIVE_DEST_STATUS
--------------------------------------------------------------------------------
SELECT * FROM v$archive_gap;
SELECT dest_id, gap_status, status, destination, error
FROM v$archive_dest_status WHERE status <> 'INACTIVE';

PROMPT
PROMPT === End of query: V$ARCHIVE_GAP and dest gap_status ===
PROMPT

-- End of file
