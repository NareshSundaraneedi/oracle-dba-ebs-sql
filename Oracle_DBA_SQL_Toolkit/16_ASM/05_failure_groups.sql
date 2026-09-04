--------------------------------------------------------------------------------
-- File Name       : 05_failure_groups.sql
-- Category        : 16_ASM
-- Purpose         : Failure group layout
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- NORMAL redundancy needs 2 FG; HIGH needs 3. Putting both disks of a mirror in one FG defeats redundancy.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: FG composition
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group by failgroup.
-- 2. Important columns
--    FAILGROUP, DISKS, GB.
-- 3. How to interpret the output
--    Uneven FG sizes cause imbalanced usable space.
-- 4. What indicates a problem
--    Only one FG on a NORMAL group.
-- 5. Recommended DBA action
--    Fix layout with storage — planned outage.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_DISK
--------------------------------------------------------------------------------
SELECT group_number, failgroup, COUNT(*) disks, ROUND(SUM(total_mb)/1024,2) total_gb
FROM v$asm_disk WHERE header_status='MEMBER'
GROUP BY group_number, failgroup ORDER BY 1,2;

PROMPT
PROMPT === End of query: FG composition ===
PROMPT

-- End of file
