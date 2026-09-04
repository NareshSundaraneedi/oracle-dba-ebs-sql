--------------------------------------------------------------------------------
-- File Name       : 05_redo_generation_rate.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Redo generation rate from V$SYSSTAT / archived logs
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Estimates MB/hour. Needed before resizing redo (target: switches every 15-30 min under peak, not every 30 seconds).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Redo size and recent archive volume
--------------------------------------------------------------------------------
-- 1. What the query does
--    SYSSTAT redo size + V$ARCHIVED_LOG last 24h.
-- 2. Important columns
--    REDO_MB, ARCH_MB_24H, SWITCHES.
-- 3. How to interpret the output
--    Archive volume ≈ redo volume on primary.
-- 4. What indicates a problem
--    >1 log switch/minute sustained.
-- 5. Recommended DBA action
--    Increase redo size or reduce generation (unnecessary indexes, supplemental log).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSSTAT, V_$ARCHIVED_LOG
--------------------------------------------------------------------------------
SELECT inst_id, ROUND(value/1024/1024,1) redo_mb_since_start
FROM gv$sysstat WHERE name = 'redo size';
SELECT COUNT(*) switches_24h,
       ROUND(SUM(blocks*block_size)/1024/1024,1) arch_mb_24h
FROM v$archived_log
WHERE first_time > SYSDATE-1 AND dest_id = 1;

PROMPT
PROMPT === End of query: Redo size and recent archive volume ===
PROMPT

-- End of file
