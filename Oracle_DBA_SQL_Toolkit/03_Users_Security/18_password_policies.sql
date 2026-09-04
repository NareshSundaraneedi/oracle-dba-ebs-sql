--------------------------------------------------------------------------------
-- File Name       : 18_password_policies.sql
-- Category        : 03_Users_Security
-- Purpose         : Extract password-related profile limits
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Password complexity, reuse, and life-time settings per profile.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Password resource limits
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_PROFILES for PASSWORD% and FAILED_LOGIN.
-- 2. Important columns
--    PROFILE, RESOURCE_NAME, LIMIT.
-- 3. How to interpret the output
--    PASSWORD_VERIFY_FUNCTION NULL means no complexity function.
-- 4. What indicates a problem
--    DEFAULT profile UNLIMITED everywhere on a production database subject to audit.
-- 5. Recommended DBA action
--    Align profiles with the security standard. Service accounts get a dedicated profile.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_PROFILES
--------------------------------------------------------------------------------
SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  resource_name LIKE 'PASSWORD%'
OR     resource_name = 'FAILED_LOGIN_ATTEMPTS'
ORDER BY profile, resource_name;

PROMPT
PROMPT === End of query: Password resource limits ===
PROMPT

-- End of file
