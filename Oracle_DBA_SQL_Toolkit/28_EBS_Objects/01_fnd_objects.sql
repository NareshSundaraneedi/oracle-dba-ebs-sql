--------------------------------------------------------------------------------
-- File Name       : 01_fnd_objects.sql
-- Category        : 28_EBS_Objects
-- Purpose         : FND / APPLSYS object counts and invalids
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- APPLSYS health.
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
-- QUERY 1: APPLSYS objects
--------------------------------------------------------------------------------
-- 1. What the query does
--    Counts + invalids.
-- 2. Important columns
--    TYPE, CNT, INVALIDS.
-- 3. How to interpret the output
--    Invalid FND packages break login.
-- 4. What indicates a problem
--    Invalids after adop.
-- 5. Recommended DBA action
--    adop compile.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT object_type, SUM(DECODE(status,'INVALID',1,0)) invalids, COUNT(*) cnt
FROM dba_objects WHERE owner='APPLSYS' GROUP BY object_type ORDER BY invalids DESC, object_type;

PROMPT
PROMPT === End of query: APPLSYS objects ===
PROMPT

-- End of file
