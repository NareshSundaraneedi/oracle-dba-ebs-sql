--------------------------------------------------------------------------------
-- File Name       : 16_invalid_objects.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : EBS-relevant invalid objects (product schemas)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Invalids in APPS, APPLSYS, and product schemas. Difference vs 05_Objects/01: filtered to EBS owners.
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
-- QUERY 1: EBS invalids
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_OBJECTS for EBS schemas.
-- 2. Important columns
--    OWNER, TYPE, NAME.
-- 3. How to interpret the output
--    A few invalids in unused products may be ignorable; APPS/APPLSYS are not.
-- 4. What indicates a problem
--    Hundreds of invalids after adop abort.
-- 5. Recommended DBA action
--    adop phase=fs_clone / compile. Review adop logs.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT owner, object_type, COUNT(*) invalids
FROM dba_objects
WHERE status='INVALID'
AND owner IN ('APPS','APPLSYS','APPS_NE','GL','AR','AP','PO','INV','ONT','HR','PA','XXCUST')
GROUP BY owner, object_type
ORDER BY invalids DESC;

SELECT owner, object_type, object_name FROM dba_objects
WHERE status='INVALID'
AND owner NOT IN ('SYS','SYSTEM','XDB')
ORDER BY owner, object_type, object_name
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: EBS invalids ===
PROMPT

-- End of file
