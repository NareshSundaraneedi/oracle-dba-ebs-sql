--------------------------------------------------------------------------------
-- File Name       : 09_synonyms.sql
-- Category        : 05_Objects
-- Purpose         : Find invalid or cross-schema synonyms
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- APPS is mostly synonyms. Invalid synonyms after a clone usually mean
-- the target schema was not imported.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Invalid synonyms and missing targets
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins DBA_SYNONYMS to DBA_OBJECTS.
-- 2. Important columns
--    OWNER, SYNONYM_NAME, TABLE_OWNER, TABLE_NAME.
-- 3. How to interpret the output
--    Missing target object = broken synonym.
-- 4. What indicates a problem
--    Thousands of invalid APPS synonyms after a partial import.
-- 5. Recommended DBA action
--    Import the missing product schema. Do not recreate synonyms by hand at scale.
-- 6. Production cautions
--    Safe. Full APPS synonym list is huge — this query lists broken ones.
-- 7. Required privileges
--    SELECT on DBA_SYNONYMS, DBA_OBJECTS
-- EBS relevance  : Critical for EBS
--------------------------------------------------------------------------------
SELECT
       s.owner,
       s.synonym_name,
       s.table_owner,
       s.table_name,
       s.db_link
FROM   dba_synonyms s
WHERE  s.db_link IS NULL
AND    NOT EXISTS (
         SELECT 1 FROM dba_objects o
         WHERE  o.owner = s.table_owner
         AND    o.object_name = s.table_name
       )
AND    s.owner NOT IN ('PUBLIC')
AND    ROWNUM <= 500
ORDER BY s.owner, s.synonym_name;

PROMPT
PROMPT === End of query: Invalid synonyms and missing targets ===
PROMPT

-- End of file
