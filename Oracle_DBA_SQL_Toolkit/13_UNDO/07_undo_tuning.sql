--------------------------------------------------------------------------------
-- File Name       : 07_undo_tuning.sql
-- Category        : 13_UNDO
-- Purpose         : Sizing estimate from undo stats
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Rough undo size ≈ undo blocks/sec * block size * retention. This is an estimate, not a mandate.
--
-- Slot length is typically 10 minutes in V$UNDOSTAT.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Undo generation rate
--------------------------------------------------------------------------------
-- 1. What the query does
--    Average undoblks per 10-min slot.
-- 2. Important columns
--    AVG_UNDOBLKS, EST_MB_FOR_RETENTION.
-- 3. How to interpret the output
--    Use peak slots, not average, for month-end.
-- 4. What indicates a problem
--    Estimate >> current undo file size.
-- 5. Recommended DBA action
--    Add datafiles. Do not shrink undo as a performance fix.
-- 6. Production cautions
--    Safe. Estimate only.
-- 7. Required privileges
--    SELECT on V_$UNDOSTAT, V_$PARAMETER
--------------------------------------------------------------------------------
WITH p AS (
  SELECT TO_NUMBER(value) ret FROM v$parameter WHERE name='undo_retention'
), b AS (
  SELECT TO_NUMBER(value) bs FROM v$parameter WHERE name='db_block_size'
)
SELECT ROUND(AVG(undoblks),1) avg_undoblks_per_slot,
       ROUND(MAX(undoblks),1) max_undoblks_per_slot,
       ROUND(MAX(undoblks)/600 * (SELECT ret FROM p) * (SELECT bs FROM b)/1024/1024,1) AS rough_mb_at_peak_for_retention
FROM v$undostat WHERE begin_time > SYSDATE-1;

PROMPT
PROMPT === End of query: Undo generation rate ===
PROMPT

-- End of file
