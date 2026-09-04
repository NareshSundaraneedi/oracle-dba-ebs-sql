--------------------------------------------------------------------------------
-- File Name       : 02_custom_objects.sql
-- Category        : 28_EBS_Objects
-- Purpose         : Custom XX schema objects
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE xx_owner. Inventory for a customization schema.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: XX objects
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_OBJECTS for custom owner.
-- 2. Important columns
--    TYPE, NAME, STATUS.
-- 3. How to interpret the output
--    Invalid XX bodies after a patch overwrote stubs.
-- 4. What indicates a problem
--    Missing XX objects after clone.
-- 5. Recommended DBA action
--    Re-import custom dump.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
DEFINE xx_owner = XXCUST
SELECT object_type, status, COUNT(*) cnt FROM dba_objects WHERE owner='&xx_owner' GROUP BY object_type, status;
SELECT object_type, object_name, status, last_ddl_time FROM dba_objects
WHERE owner='&xx_owner' AND status='INVALID';

PROMPT
PROMPT === End of query: XX objects ===
PROMPT

-- End of file
