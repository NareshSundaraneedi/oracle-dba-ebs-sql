--------------------------------------------------------------------------------
-- File Name       : 29_objects_by_owner.sql
-- Category        : 01_Basic
-- Purpose         : Count objects by owner and type
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Inventory used to compare a clone to production and to find unexpected
-- object types (for example a user creating tables in APPS).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Object counts by owner and type
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates DBA_OBJECTS.
-- 2. Important columns
--    OWNER, OBJECT_TYPE, OBJECT_COUNT.
-- 3. How to interpret the output
--    EBS has a well-known shape: many synonyms in APPS, tables in product schemas.
-- 4. What indicates a problem
--    Application user owning tables in SYSTEM or SYSAUX. Sudden new object type counts after a failed clone.
-- 5. Recommended DBA action
--    Investigate unexpected owners. Do not drop objects from this script.
-- 6. Production cautions
--    Safe. Can be large on EBS — summary query is cheap.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       owner,
       object_type,
       COUNT(*) AS object_count
FROM   dba_objects
WHERE  owner NOT IN ('SYS','SYSTEM','XDB','MDSYS','CTXSYS','WMSYS','ORDDATA','ORDSYS')
GROUP BY owner, object_type
ORDER BY owner, object_type;

PROMPT
PROMPT === End of query: Object counts by owner and type ===
PROMPT

-- End of file
