--------------------------------------------------------------------------------
-- File Name       : 12_request_groups.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Request groups and program assignments
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Why a user cannot submit a program: responsibility → request group → program.
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
-- QUERY 1: Request group contents
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_REQUEST_GROUPS + FND_REQUEST_GROUP_UNITS.
-- 2. Important columns
--    REQUEST_GROUP_NAME, UNIT_TYPE, PROGRAM.
-- 3. How to interpret the output
--    UNIT_TYPE P=program A=application.
-- 4. What indicates a problem
--    Custom program not in the request group used by the responsibility.
-- 5. Recommended DBA action
--    Add via Security > Responsibility > Request. Not SQL insert.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE rg = %System Administrator%

SELECT rg.request_group_name, rg.application_id,
       rgu.request_unit_type, rgu.unit_application_id,
       fcp.concurrent_program_name, fcp.user_concurrent_program_name
FROM fnd_request_groups rg
JOIN fnd_request_group_units rgu ON rgu.request_group_id = rg.request_group_id
LEFT JOIN fnd_concurrent_programs_vl fcp
       ON fcp.concurrent_program_id = rgu.request_unit_id
      AND rgu.request_unit_type = 'P'
WHERE rg.request_group_name LIKE '&rg'
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Request group contents ===
PROMPT

-- End of file
