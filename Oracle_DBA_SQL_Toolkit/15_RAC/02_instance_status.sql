--------------------------------------------------------------------------------
-- File Name       : 02_instance_status.sql
-- Category        : 15_RAC
-- Purpose         : Per-instance status, blocked, logins
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 01: focuses on health flags (BLOCKED, LOGINS) not just membership.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: GV$INSTANCE health
--------------------------------------------------------------------------------
-- 1. What the query does
--    Status flags.
-- 2. Important columns
--    STATUS, BLOCKED, LOGINS, ARCHIVER.
-- 3. How to interpret the output
--    BLOCKED YES is rare and serious.
-- 4. What indicates a problem
--    An instance MOUNTED while others OPEN.
-- 5. Recommended DBA action
--    Alert log / CRS.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$INSTANCE
--------------------------------------------------------------------------------
SELECT inst_id, instance_name, status, database_status, blocked, logins, archiver, shutdown_pending
FROM gv$instance ORDER BY inst_id;

PROMPT
PROMPT === End of query: GV$INSTANCE health ===
PROMPT

-- End of file
