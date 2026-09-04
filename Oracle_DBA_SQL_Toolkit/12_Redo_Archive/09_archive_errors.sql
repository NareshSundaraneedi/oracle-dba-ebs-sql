--------------------------------------------------------------------------------
-- File Name       : 09_archive_errors.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Destinations in ERROR / DEFERRED
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Immediate production check when archiving hangs.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Error dests
--------------------------------------------------------------------------------
-- 1. What the query does
--    STATUS not VALID.
-- 2. Important columns
--    ERROR text.
-- 3. How to interpret the output
--    ORA-00257 is FRA/archive full.
-- 4. What indicates a problem
--    Any ERROR on dest 1 (local).
-- 5. Recommended DBA action
--    Free FRA (02/08). Do not delete archive files at OS without RMAN.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVE_DEST
--------------------------------------------------------------------------------
SELECT dest_id, status, error, destination FROM v$archive_dest
WHERE status NOT IN ('INACTIVE','VALID') OR error IS NOT NULL;

PROMPT
PROMPT === End of query: Error dests ===
PROMPT

-- End of file
