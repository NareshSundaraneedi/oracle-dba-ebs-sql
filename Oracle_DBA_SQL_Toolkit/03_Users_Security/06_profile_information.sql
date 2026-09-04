--------------------------------------------------------------------------------
-- File Name       : 06_profile_information.sql
-- Category        : 03_Users_Security
-- Purpose         : List profiles and resource/password limits
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Profiles control failed-login lockout, password life, and idle time.
-- A too-aggressive DEFAULT profile locks EBS batch users.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Profile limits and user counts
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_PROFILES and counts users per profile.
-- 2. Important columns
--    PROFILE, RESOURCE_NAME, LIMIT, USER_COUNT.
-- 3. How to interpret the output
--    FAILED_LOGIN_ATTEMPTS UNLIMITED is weak. PASSWORD_LIFE_TIME 60 on APPS is dangerous.
-- 4. What indicates a problem
--    IDLE_TIME set on application users causing random disconnects. FAILED_LOGIN_ATTEMPTS 3 on shared batch accounts.
-- 5. Recommended DBA action
--    Create a dedicated profile for service accounts. Do not ALTER PROFILE in production without approval.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on DBA_PROFILES, DBA_USERS
--------------------------------------------------------------------------------
SELECT profile, resource_type, resource_name, limit
FROM   dba_profiles
ORDER BY profile, resource_type, resource_name;

SELECT profile, COUNT(*) AS user_count
FROM   dba_users
GROUP BY profile
ORDER BY user_count DESC;

PROMPT
PROMPT === End of query: Profile limits and user counts ===
PROMPT

-- End of file
