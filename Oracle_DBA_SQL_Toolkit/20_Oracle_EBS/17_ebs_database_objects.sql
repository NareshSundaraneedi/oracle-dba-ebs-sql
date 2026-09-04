--------------------------------------------------------------------------------
-- File Name       : 17_ebs_database_objects.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Object counts for EBS product schemas
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shape of the EBS database for clone comparison.
--
-- Requires EBS R12.2 objects (APPLSYS/APPS). Will fail on a non-EBS database.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Counts
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_OBJECTS group by owner.
-- 2. Important columns
--    OWNER, TYPE, CNT.
-- 3. How to interpret the output
--    APPS has mostly synonyms/packages. Product schemas have tables.
-- 4. What indicates a problem
--    GL table count far below production after an incomplete export.
-- 5. Recommended DBA action
--    Re-import the product schema.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT owner, object_type, COUNT(*) cnt
FROM dba_objects
WHERE owner IN (SELECT oracle_username FROM fnd_oracle_userid)
GROUP BY owner, object_type
ORDER BY owner, object_type;

PROMPT
PROMPT === End of query: Counts ===
PROMPT

-- End of file
