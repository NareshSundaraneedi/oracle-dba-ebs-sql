--------------------------------------------------------------------------------
-- File Name       : 08_rebalance_power.sql
-- Category        : 16_ASM
-- Purpose         : Current power and how to change it (generated)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- POWER 0-n. Generated ALTER only.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Power display and generate
--------------------------------------------------------------------------------
-- 1. What the query does
--    Current operations + generate command.
-- 2. Important columns
--    POWER.
-- 3. How to interpret the output
--    Higher power finishes faster, more I/O impact.
-- 4. What indicates a problem
--    Rebalance killing OLTP I/O.
-- 5. Recommended DBA action
--    WARNING: generated ALTER DISKGROUP ... REBALANCE POWER n;
-- 6. Production cautions
--    WARNING: Do not execute blindly.
-- 7. Required privileges
--    SELECT on V_$ASM_OPERATION, V_$ASM_DISKGROUP
--------------------------------------------------------------------------------
SELECT name, state FROM v$asm_diskgroup;
SELECT group_number, operation, power, est_minutes FROM v$asm_operation;
-- WARNING: Review carefully before executing.
-- SELECT 'ALTER DISKGROUP '||name||' REBALANCE POWER 2;' FROM v$asm_diskgroup;

PROMPT
PROMPT === End of query: Power display and generate ===
PROMPT

-- End of file
