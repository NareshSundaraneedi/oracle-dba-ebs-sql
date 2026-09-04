--------------------------------------------------------------------------------
-- File Name       : 09_asm_attributes.sql
-- Category        : 16_ASM
-- Purpose         : Diskgroup attributes (compatible, au_size, thin_provisioned)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- COMPATIBLE.ASM / RDBMS must match your RU plan. AU_SIZE 4M is common on 12c+.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$ASM_ATTRIBUTE
--------------------------------------------------------------------------------
-- 1. What the query does
--    Attributes.
-- 2. Important columns
--    NAME, VALUE.
-- 3. How to interpret the output
--    compatible.rdbms too high can block older instances.
-- 4. What indicates a problem
--    Unexpected thin_provisioned / sector size.
-- 5. Recommended DBA action
--    Change attributes only with a plan (some require rebalance).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_ATTRIBUTE
--------------------------------------------------------------------------------
SELECT group_number, name, value FROM v$asm_attribute
WHERE name IN ('compatible.asm','compatible.rdbms','au_size','sector_size','thin_provisioned','disk_repair_time')
OR name LIKE 'cell%'
ORDER BY group_number, name;

PROMPT
PROMPT === End of query: V$ASM_ATTRIBUTE ===
PROMPT

-- End of file
