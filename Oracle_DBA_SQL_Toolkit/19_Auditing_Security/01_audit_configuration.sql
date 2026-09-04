--------------------------------------------------------------------------------
-- File Name       : 01_audit_configuration.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Unified audit vs traditional audit_trail parameter
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows whether unified auditing is enabled (AUDIT_TRAIL parameter plus UNIFIED_AUDIT option). Fresh 19c often has unified audit on.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Audit configuration
--------------------------------------------------------------------------------
-- 1. What the query does
--    Parameters + V$OPTION Unified Auditing.
-- 2. Important columns
--    AUDIT_TRAIL, UNIFIED_AUDITING option.
-- 3. How to interpret the output
--    UNIFIED and traditional can both be in mixed mode on upgrades.
-- 4. What indicates a problem
--    No audit trail on a regulated production DB.
-- 5. Recommended DBA action
--    Enabling unified audit requires a relink/option — project work, not an incident toggle.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$OPTION
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter
WHERE name IN ('audit_trail','audit_sys_operations','unified_audit_sga_queue_size');
SELECT parameter, value FROM v$option WHERE parameter LIKE '%Audit%';

PROMPT
PROMPT === End of query: Audit configuration ===
PROMPT

-- End of file
