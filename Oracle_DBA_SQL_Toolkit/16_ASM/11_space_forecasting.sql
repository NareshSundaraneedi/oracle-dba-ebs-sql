--------------------------------------------------------------------------------
-- File Name       : 11_space_forecasting.sql
-- Category        : 16_ASM
-- Purpose         : Simple days-to-full estimate from two snapshots of FREE_MB
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ASM has no built-in growth table. This prints current free space and instructs you to compare to yesterday's spool. Optional AWR not used (pack).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Current free snapshot
--------------------------------------------------------------------------------
-- 1. What the query does
--    Prints a dated snapshot you should save daily.
-- 2. Important columns
--    NAME, USABLE_GB, SNAP_TIME.
-- 3. How to interpret the output
--    Save output; compute (free_yesterday-free_today) for a daily burn rate.
-- 4. What indicates a problem
--    Burn rate that exhausts usable in < 14 days.
-- 5. Recommended DBA action
--    Add storage before 85%.
-- 6. Production cautions
--    Safe. Not a statistical forecast.
-- 7. Required privileges
--    SELECT on V_$ASM_DISKGROUP
--------------------------------------------------------------------------------
SELECT SYSDATE snap_time, name,
       ROUND(usable_file_mb/1024,2) usable_gb,
       ROUND(free_mb/1024,2) free_gb
FROM v$asm_diskgroup;
PROMPT Compare this spool to yesterday. days_left ≈ usable_gb / daily_burn_gb.

PROMPT
PROMPT === End of query: Current free snapshot ===
PROMPT

-- End of file
