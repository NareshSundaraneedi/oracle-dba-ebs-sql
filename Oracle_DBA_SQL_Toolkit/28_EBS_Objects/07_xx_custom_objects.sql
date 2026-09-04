--------------------------------------------------------------------------------
-- File Name       : 07_xx_custom_objects.sql
-- Category        : 28_EBS_Objects
-- Purpose         : Objects whose names start with XX in APPS/custom schemas
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Naming-standard hunt for customizations living in APPS.
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
-- QUERY 1: XX% objects
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_OBJECTS object_name LIKE XX%.
-- 2. Important columns
--    OWNER, NAME, TYPE.
-- 3. How to interpret the output
--    Custom packages in APPS should usually live in an XX schema with APPS synonym.
-- 4. What indicates a problem
--    XX tables created in APPS.
-- 5. Recommended DBA action
--    Move with a project — do not drop.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT owner, object_type, object_name, status
FROM dba_objects WHERE object_name LIKE 'XX%'
AND owner NOT IN ('SYS','SYSTEM')
ORDER BY owner, object_type, object_name
FETCH FIRST 300 ROWS ONLY;

PROMPT
PROMPT === End of query: XX% objects ===
PROMPT

-- End of file
