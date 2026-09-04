--------------------------------------------------------------------------------
-- File Name       : 01_asm_diskgroups.sql
-- Category        : 16_ASM
-- Purpose         : Diskgroup inventory and state
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- STATE MOUNTED and TYPE EXTERNAL/NORMAL/HIGH.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$ASM_DISKGROUP
--------------------------------------------------------------------------------
-- 1. What the query does
--    Groups.
-- 2. Important columns
--    NAME, STATE, TYPE, TOTAL_MB, FREE_MB.
-- 3. How to interpret the output
--    DISMOUNTED is an outage for files in that group.
-- 4. What indicates a problem
--    STATE not CONNECTED/MOUNTED.
-- 5. Recommended DBA action
--    ASM instance / srvctl status diskgroup.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_DISKGROUP
--------------------------------------------------------------------------------
SELECT group_number, name, state, type, compatibility, database_compatibility,
       ROUND(total_mb/1024,2) total_gb, ROUND(free_mb/1024,2) free_gb, ROUND(usable_file_mb/1024,2) usable_gb
FROM v$asm_diskgroup ORDER BY name;

PROMPT
PROMPT === End of query: V$ASM_DISKGROUP ===
PROMPT

-- End of file
