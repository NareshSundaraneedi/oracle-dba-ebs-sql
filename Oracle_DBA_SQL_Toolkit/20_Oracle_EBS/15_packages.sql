--------------------------------------------------------------------------------
-- File Name       : 15_packages.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : APPS packages invalid or recently changed
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- APPS owns packages (often wrappers). Invalid APPS packages break concurrent PL/SQL programs.
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
-- QUERY 1: APPS package health
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_OBJECTS packages for APPS.
-- 2. Important columns
--    OBJECT_NAME, STATUS, LAST_DDL_TIME.
-- 3. How to interpret the output
--    Mass LAST_DDL after adop compile is expected.
-- 4. What indicates a problem
--    Invalid XX custom packages after a patch overwrote customizations (R12.2 editions / fs).
-- 5. Recommended DBA action
--    Use adop compile / adadmin. See 28_EBS_Objects.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT status, COUNT(*) FROM dba_objects
WHERE owner='APPS' AND object_type IN ('PACKAGE','PACKAGE BODY')
GROUP BY status;

SELECT object_type, object_name, last_ddl_time
FROM dba_objects
WHERE owner='APPS' AND status='INVALID'
AND object_type IN ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION')
ORDER BY object_name;

PROMPT
PROMPT === End of query: APPS package health ===
PROMPT

-- End of file
