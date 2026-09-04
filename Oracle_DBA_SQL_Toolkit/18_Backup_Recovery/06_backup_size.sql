--------------------------------------------------------------------------------
-- File Name       : 06_backup_size.sql
-- Category        : 18_Backup_Recovery
-- Purpose         : Backup piece sizes from V$BACKUP_PIECE
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Piece-level sizes for tape/capacity planning.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Pieces
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$BACKUP_PIECE last 7 days.
-- 2. Important columns
--    SET_STAMP, BYTES, STATUS, HANDLE.
-- 3. How to interpret the output
--    DELETED pieces are gone from disk/tape inventory.
-- 4. What indicates a problem
--    Pieces STATUS EXPIRED (need CROSSCHECK).
-- 5. Recommended DBA action
--    RMAN CROSSCHECK / DELETE EXPIRED — change, generated as prompt.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$BACKUP_PIECE
--------------------------------------------------------------------------------
SELECT set_stamp, set_count, piece#, status,
       ROUND(bytes/1024/1024/1024,2) gb,
       start_time, handle
FROM v$backup_piece
WHERE start_time > SYSDATE-7
ORDER BY start_time DESC;

PROMPT
PROMPT === End of query: Pieces ===
PROMPT

-- End of file
