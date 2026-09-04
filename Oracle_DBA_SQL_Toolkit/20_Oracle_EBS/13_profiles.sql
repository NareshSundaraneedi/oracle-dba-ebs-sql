--------------------------------------------------------------------------------
-- File Name       : 13_profiles.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Profile option values at site/app/resp/user
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_PROFILE_OPTIONS + FND_PROFILE_OPTION_VALUES. Classic clone issue: site-level profiles still point at production hosts.
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
-- QUERY 1: Profile values for a name
--------------------------------------------------------------------------------
-- 1. What the query does
--    Join options to values and resolve level.
-- 2. Important columns
--    PROFILE_OPTION_NAME, LEVEL, VALUE.
-- 3. How to interpret the output
--    Levels: 10001 site, 10002 app, 10003 resp, 10004 user (check lookup).
-- 4. What indicates a problem
--    ICX_SESSION_TIMEOUT, apps listener, or outbound mail still at source values after clone.
-- 5. Recommended DBA action
--    Change via System Administrator Profiles. Avoid direct UPDATEs.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE prof = %APPS_DATABASE%

SELECT po.profile_option_name, po.user_profile_option_name,
       DECODE(pov.level_id, 10001,'SITE',10002,'APPLICATION',10003,'RESPONSIBILITY',10004,'USER', TO_CHAR(pov.level_id)) AS lvl,
       pov.profile_option_value,
       pov.level_value
FROM fnd_profile_options_vl po
JOIN fnd_profile_option_values pov ON pov.profile_option_id = po.profile_option_id
WHERE po.profile_option_name LIKE '&prof'
   OR po.user_profile_option_name LIKE '&prof'
ORDER BY po.profile_option_name, pov.level_id;

PROMPT
PROMPT === End of query: Profile values for a name ===
PROMPT

-- End of file
