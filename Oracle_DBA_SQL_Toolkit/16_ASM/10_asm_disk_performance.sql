--------------------------------------------------------------------------------
-- File Name       : 10_asm_disk_performance.sql
-- Category        : 16_ASM
-- Purpose         : Disk-level I/O stats from ASM
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ASM_DISK_IOSTAT / V$ASM_DISK performance columns. Find the slow disk.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Disk I/O
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads/writes and errors.
-- 2. Important columns
--    READS, WRITES, READ_ERRS, WRITE_ERRS, READ_TIME.
-- 3. How to interpret the output
--    One disk with errors or vastly higher time.
-- 4. What indicates a problem
--    READ_ERRS > 0.
-- 5. Recommended DBA action
--    Replace/investigate that LUN. Do not rebalance onto a failing disk.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_DISK_STAT, V_$ASM_DISK
--------------------------------------------------------------------------------
SELECT name, path, reads, writes, read_errs, write_errs,
       ROUND(read_time,1) read_time, ROUND(write_time,1) write_time
FROM v$asm_disk_stat
ORDER BY read_errs DESC, write_errs DESC, read_time DESC;

PROMPT
PROMPT === End of query: Disk I/O ===
PROMPT

-- End of file
