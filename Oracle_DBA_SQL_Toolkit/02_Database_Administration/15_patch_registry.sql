--------------------------------------------------------------------------------
-- File Name       : 15_patch_registry.sql
-- Category        : 02_Database_Administration
-- Purpose         : Combine SQL patch registry with opatch-equivalent inventory in-db
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- In-database view of datapatch history plus DBA_REGISTRY status.
-- OS opatch lsinventory remains required for binary one-offs.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL patches and registry status
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins DBA_REGISTRY_SQLPATCH with invalid DBA_REGISTRY components.
-- 2. Important columns
--    PATCH_ID, STATUS, ACTION, COMP_ID, COMP_STATUS.
-- 3. How to interpret the output
--    Binary patched + SQL WITH ERRORS is a half-patched database.
-- 4. What indicates a problem
--    Any component INVALID after a patch window.
-- 5. Recommended DBA action
--    Rerun datapatch. Review sqlpatch logs. Do not start EBS services until VALID.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_REGISTRY_SQLPATCH, DBA_REGISTRY
--------------------------------------------------------------------------------
SELECT patch_id, version, status, action, description, action_time
FROM   dba_registry_sqlpatch
ORDER BY action_time DESC;

SELECT comp_id, comp_name, version, status
FROM   dba_registry
WHERE  status <> 'VALID'
ORDER BY comp_id;

PROMPT
PROMPT === End of query: SQL patches and registry status ===
PROMPT

-- End of file
