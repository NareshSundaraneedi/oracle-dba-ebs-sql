--------------------------------------------------------------------------------
-- File Name       : 02_diskgroup_usage.sql
-- Category        : 16_ASM
-- Purpose         : Usage with 70/85/95 bands using usable space
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Use USABLE_FILE_MB for NORMAL/HIGH redundancy.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Usage alerts
--------------------------------------------------------------------------------
-- 1. What the query does
--    Used percent of usable.
-- 2. Important columns
--    USED_PCT, ALERT.
-- 3. How to interpret the output
--    EXTERNAL: usable ≈ free. NORMAL: usable accounts for mirror.
-- 4. What indicates a problem
--    >85% WARNING on DATA or FRA groups.
-- 5. Recommended DBA action
--    Add disks or move data. Rebalance will start.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_DISKGROUP
--------------------------------------------------------------------------------
SELECT name, type,
       ROUND((1-usable_file_mb/NULLIF(total_mb,0))*100,1) used_pct_usable,
       CASE WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>95 THEN 'CRITICAL'
            WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>85 THEN 'WARNING'
            WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>70 THEN 'MONITOR'
            ELSE 'NORMAL' END alert_level
FROM v$asm_diskgroup;

PROMPT
PROMPT === End of query: Usage alerts ===
PROMPT

-- End of file
