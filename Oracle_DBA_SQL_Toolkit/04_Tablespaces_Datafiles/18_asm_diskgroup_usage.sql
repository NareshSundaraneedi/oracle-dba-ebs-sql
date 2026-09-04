--------------------------------------------------------------------------------
-- File Name       : 18_asm_diskgroup_usage.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : ASM diskgroup free space from the RDBMS instance
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ASM_DISKGROUP is visible from the database instance when ASM is used.
-- Full diskgroup analysis is in folder 16_ASM. Alert bands 70/85/95.
--
-- Requires ASM. Returns no rows on file-system storage.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Diskgroup usage from the database
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$ASM_DISKGROUP.
-- 2. Important columns
--    NAME, TOTAL_GB, USABLE_FILE_GB, PCT_USED, STATE.
-- 3. How to interpret the output
--    USABLE_FILE_MB accounts for redundancy. Use that, not raw TOTAL-FREE, for EXTERNAL vs NORMAL.
-- 4. What indicates a problem
--    PCT_USED > 85 on the diskgroup that holds data or FRA.
-- 5. Recommended DBA action
--    Add disks or move files. See 16_ASM. Do not drop disks during peak.
-- 6. Production cautions
--    Safe. STATE CONNECTED from DB instance is normal.
-- 7. Required privileges
--    SELECT on V_$ASM_DISKGROUP
--
-- ASM where applicable.
--------------------------------------------------------------------------------
SELECT
       name,
       state,
       type,
       ROUND(total_mb/1024,2) AS total_gb,
       ROUND(free_mb/1024,2) AS free_gb,
       ROUND(usable_file_mb/1024,2) AS usable_file_gb,
       ROUND((1 - (usable_file_mb/NULLIF(total_mb,0))) * 100,1) AS used_pct_approx,
       CASE
         WHEN (1 - (usable_file_mb/NULLIF(total_mb,0))) * 100 > 95 THEN 'CRITICAL'
         WHEN (1 - (usable_file_mb/NULLIF(total_mb,0))) * 100 > 85 THEN 'WARNING'
         WHEN (1 - (usable_file_mb/NULLIF(total_mb,0))) * 100 > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   v$asm_diskgroup
ORDER BY name;

PROMPT
PROMPT === End of query: Diskgroup usage from the database ===
PROMPT

-- End of file
