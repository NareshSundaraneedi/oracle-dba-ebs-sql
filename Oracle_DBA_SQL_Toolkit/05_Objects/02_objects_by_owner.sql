--------------------------------------------------------------------------------
-- File Name       : 02_objects_by_owner.sql
-- Category        : 05_Objects
-- Purpose         : Object inventory for one owner
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Filtered inventory. Use for custom XX schemas or a product schema
-- after a patch.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Objects for one owner
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lists DBA_OBJECTS for &owner_p.
-- 2. Important columns
--    OBJECT_TYPE, OBJECT_NAME, STATUS, LAST_DDL_TIME.
-- 3. How to interpret the output
--    LAST_DDL_TIME clustering after a patch is expected.
-- 4. What indicates a problem
--    Unexpected tables in APPS (should be synonyms).
-- 5. Recommended DBA action
--    Investigate object origin. Do not drop.
-- 6. Production cautions
--    Safe. Result can be large — filter.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
DEFINE owner_p = XXCUST

SELECT object_type, COUNT(*) cnt
FROM   dba_objects
WHERE  owner = '&owner_p'
GROUP BY object_type
ORDER BY cnt DESC;

SELECT object_type, object_name, status, created, last_ddl_time
FROM   dba_objects
WHERE  owner = '&owner_p'
ORDER BY object_type, object_name;

PROMPT
PROMPT === End of query: Objects for one owner ===
PROMPT

-- End of file
