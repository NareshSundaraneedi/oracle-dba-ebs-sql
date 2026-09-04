--------------------------------------------------------------------------------
-- File Name       : 07_asm_rebalance.sql
-- Category        : 16_ASM
-- Purpose         : Rebalance operations in progress
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ASM_OPERATION shows EST_MINUTES. I/O impact is real — do not power up to 11 on peak without a decision.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ASM operations
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$ASM_OPERATION.
-- 2. Important columns
--    OPERATION, STATE, POWER, EST_MINUTES.
-- 3. How to interpret the output
--    REBAL RUNNING is expected after add/drop disk.
-- 4. What indicates a problem
--    REBAL hung (EST_MINUTES not moving, STATE WAIT).
-- 5. Recommended DBA action
--    Check ASM alert. Adjust POWER in a controlled way (08).
-- 6. Production cautions
--    Safe. ALTER DISKGROUP REBALANCE is a change.
-- 7. Required privileges
--    SELECT on V_$ASM_OPERATION
--------------------------------------------------------------------------------
SELECT group_number, operation, state, power, actual, sofar, est_work, est_rate, est_minutes
FROM v$asm_operation;

PROMPT
PROMPT === End of query: ASM operations ===
PROMPT

-- End of file
