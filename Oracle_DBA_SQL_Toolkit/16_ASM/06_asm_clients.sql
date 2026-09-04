--------------------------------------------------------------------------------
-- File Name       : 06_asm_clients.sql
-- Category        : 16_ASM
-- Purpose         : Who is using the diskgroups
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ASM_CLIENT lists databases (and ASM) connected.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Clients
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$ASM_CLIENT.
-- 2. Important columns
--    DB_NAME, STATUS, SOFTWARE_VERSION.
-- 3. How to interpret the output
--    STATUS CONNECTED is healthy.
-- 4. What indicates a problem
--    A database missing after a crash.
-- 5. Recommended DBA action
--    Check that instance's ASM communication / CSS.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ASM_CLIENT
--------------------------------------------------------------------------------
SELECT inst_id, group_number, instance_name, db_name, status, software_version, compatible_version
FROM v$asm_client ORDER BY db_name, instance_name;

PROMPT
PROMPT === End of query: Clients ===
PROMPT

-- End of file
