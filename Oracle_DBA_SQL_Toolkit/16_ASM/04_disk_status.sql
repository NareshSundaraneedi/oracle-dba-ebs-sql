--------------------------------------------------------------------------------
-- File Name       : 04_disk_status.sql
-- Category        : 16_ASM
-- Purpose         : Disks not ONLINE / HEADER not MEMBER
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Failed disks are a redundancy incident.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Unhealthy disks
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filter bad statuses.
-- 2. Important columns
--    HEADER_STATUS, MODE_STATUS, STATE.
-- 3. How to interpret the output
--    MISSING + FORCING is an emergency.
-- 4. What indicates a problem
--    Any disk not ONLINE in a mounted group.
-- 5. Recommended DBA action
--    Storage path / multipath. Do not FORCE immediately.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_DISK
--------------------------------------------------------------------------------
SELECT name, path, header_status, mode_status, state, failgroup
FROM v$asm_disk
WHERE header_status NOT IN ('MEMBER','CANDIDATE','PROVISIONED')
   OR NVL(mode_status,'x') <> 'ONLINE'
   OR NVL(state,'x') <> 'NORMAL';

PROMPT
PROMPT === End of query: Unhealthy disks ===
PROMPT

-- End of file
