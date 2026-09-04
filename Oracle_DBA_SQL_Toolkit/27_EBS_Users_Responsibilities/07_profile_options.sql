--------------------------------------------------------------------------------
-- File Name       : 07_profile_options.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Profile values for one user or site
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE prof and optional user.
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
-- QUERY 1: Profiles
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_PROFILE_OPTION_VALUES resolved.
-- 2. Important columns
--    LEVEL, VALUE.
-- 3. How to interpret the output
--    User level overrides site.
-- 4. What indicates a problem
--    Clone leftover URL profiles.
-- 5. Recommended DBA action
--    20/13.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE prof = %ICX%
SELECT po.profile_option_name,
       DECODE(pov.level_id,10001,'SITE',10002,'APP',10003,'RESP',10004,'USER',TO_CHAR(pov.level_id)) lvl,
       pov.profile_option_value
FROM fnd_profile_options_vl po
JOIN fnd_profile_option_values pov ON pov.profile_option_id=po.profile_option_id
WHERE po.profile_option_name LIKE '&prof' OR po.user_profile_option_name LIKE '&prof'
ORDER BY po.profile_option_name, pov.level_id;

PROMPT
PROMPT === End of query: Profiles ===
PROMPT

-- End of file
