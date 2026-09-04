--------------------------------------------------------------------------------
-- File Name       : 03_object_counts.sql
-- Category        : 05_Objects
-- Purpose         : Database-wide object counts excluding Oracle-maintained schemas
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Quick shape of the database for clone vs production comparison.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Counts by owner and type
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates DBA_OBJECTS excluding oracle_maintained users.
-- 2. Important columns
--    OWNER, OBJECT_TYPE, CNT.
-- 3. How to interpret the output
--    Compare to a saved baseline after refresh.
-- 4. What indicates a problem
--    Object counts far below production after an incomplete clone.
-- 5. Recommended DBA action
--    Re-run the clone export/import for missing schemas.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS, DBA_USERS
--------------------------------------------------------------------------------
SELECT o.owner, o.object_type, COUNT(*) cnt
FROM   dba_objects o
JOIN   dba_users u ON u.username = o.owner
WHERE  u.oracle_maintained = 'N'
GROUP BY o.owner, o.object_type
ORDER BY o.owner, o.object_type;

PROMPT
PROMPT === End of query: Counts by owner and type ===
PROMPT

-- End of file
