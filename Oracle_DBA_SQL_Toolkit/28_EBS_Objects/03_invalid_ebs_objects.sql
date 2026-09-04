--------------------------------------------------------------------------------
-- File Name       : 03_invalid_ebs_objects.sql
-- Category        : 28_EBS_Objects
-- Purpose         : Invalids in APPS, APPLSYS, and product schemas
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- EBS-focused invalid list.
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
-- QUERY 1: Invalids
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_OBJECTS status INVALID EBS owners.
-- 2. Important columns
--    OWNER, NAME, TYPE.
-- 3. How to interpret the output
--    Compile path: utlrp for SYS, adop/adadmin for APPS.
-- 4. What indicates a problem
--    APPS invalids > 0 after a failed compile.
-- 5. Recommended DBA action
--    05_Objects/01 generate compile — custom only.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT owner, object_type, object_name, last_ddl_time
FROM dba_objects WHERE status='INVALID'
AND owner IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY owner, object_type, object_name;

PROMPT
PROMPT === End of query: Invalids ===
PROMPT

-- End of file
