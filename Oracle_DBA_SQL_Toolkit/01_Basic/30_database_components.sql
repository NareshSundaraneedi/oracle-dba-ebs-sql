--------------------------------------------------------------------------------
-- File Name       : 30_database_components.sql
-- Category        : 01_Basic
-- Purpose         : List installed database components and versions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DBA_REGISTRY shows components (CATALOG, CATPROC, JAVAVM, XML, OLS, etc.)
-- and whether they are VALID after a patch.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Registry components
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_REGISTRY for component status.
-- 2. Important columns
--    COMP_ID, COMP_NAME, VERSION, STATUS, MODIFIED.
-- 3. How to interpret the output
--    STATUS VALID is required after datapatch. OPTION OFF is not the same as INVALID.
-- 4. What indicates a problem
--    STATUS INVALID or LOADING after a failed datapatch / RU.
-- 5. Recommended DBA action
--    Rerun datapatch from the new home. Collect DBA_REGISTRY_SQLPATCH. Do not compile catalog objects randomly.
-- 6. Production cautions
--    Safe. datapatch is a maintenance action.
-- 7. Required privileges
--    SELECT on DBA_REGISTRY
--------------------------------------------------------------------------------
SELECT
       comp_id,
       comp_name,
       version,
       status,
       modified,
       schema
FROM   dba_registry
ORDER BY comp_id;

PROMPT
PROMPT === End of query: Registry components ===
PROMPT

-- End of file
