--------------------------------------------------------------------------------
-- File Name       : 02_ebs_application_information.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Registered applications and basepath
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_APPLICATION lists product short names (GL, AR, XX). Used to confirm custom apps are registered.
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
-- QUERY 1: FND applications
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_APPLICATION_VL.
-- 2. Important columns
--    APPLICATION_SHORT_NAME, APPLICATION_NAME, BASEPATH.
-- 3. How to interpret the output
--    Custom XX apps should be present after a clone if they were in the export.
-- 4. What indicates a problem
--    Missing custom application after a refresh.
-- 5. Recommended DBA action
--    Re-register via System Administrator or AD utilities — not SQL inserts.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT application_id, application_short_name, application_name, basepath
FROM fnd_application_vl
ORDER BY application_short_name;

PROMPT
PROMPT === End of query: FND applications ===
PROMPT

-- End of file
