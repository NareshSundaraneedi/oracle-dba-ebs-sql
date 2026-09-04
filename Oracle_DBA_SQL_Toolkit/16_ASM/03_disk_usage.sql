--------------------------------------------------------------------------------
-- File Name       : 03_disk_usage.sql
-- Category        : 16_ASM
-- Purpose         : Per-disk size and used
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Imbalanced disks indicate a rebalance needed or a new disk just added.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$ASM_DISK
--------------------------------------------------------------------------------
-- 1. What the query does
--    Disks.
-- 2. Important columns
--    NAME, TOTAL_MB, FREE_MB, HEADER_STATUS.
-- 3. How to interpret the output
--    PROVISIONED / CANDIDATE are not in a group yet.
-- 4. What indicates a problem
--    One disk much fuller than peers in the same group.
-- 5. Recommended DBA action
--    Check rebalance (07). Do not drop disks at peak.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_DISK
--------------------------------------------------------------------------------
SELECT group_number, disk_number, name, path, header_status, mode_status, state,
       ROUND(total_mb/1024,2) total_gb, ROUND(free_mb/1024,2) free_gb
FROM v$asm_disk ORDER BY group_number, disk_number;

PROMPT
PROMPT === End of query: V$ASM_DISK ===
PROMPT

-- End of file
