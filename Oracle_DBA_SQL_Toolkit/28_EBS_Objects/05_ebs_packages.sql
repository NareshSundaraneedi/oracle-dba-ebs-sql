--------------------------------------------------------------------------------
-- File Name       : 05_ebs_packages.sql
-- Category        : 28_EBS_Objects
-- Purpose         : Invalid or recently changed APPS packages
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Patch impact.
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
-- QUERY 1: APPS packages
--------------------------------------------------------------------------------
-- 1. What the query does
--    PACKAGE/BODY last_ddl 7 days or invalid.
-- 2. Important columns
--    NAME, STATUS, LAST_DDL.
-- 3. How to interpret the output
--    Mass compile updates last_ddl for everything.
-- 4. What indicates a problem
--    Single package changed with no patch — unauthorized customize.
-- 5. Recommended DBA action
--    Diff vs source.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT object_name, object_type, status, last_ddl_time
FROM dba_objects WHERE owner='APPS' AND object_type IN ('PACKAGE','PACKAGE BODY')
AND (status='INVALID' OR last_ddl_time>SYSDATE-7)
ORDER BY last_ddl_time DESC;

PROMPT
PROMPT === End of query: APPS packages ===
PROMPT

-- End of file
