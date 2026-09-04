--------------------------------------------------------------------------------
-- File Name       : 05_menus.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Menu attached to a responsibility
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE resp_name.
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
-- QUERY 1: Menu
--------------------------------------------------------------------------------
-- 1. What the query does
--    Resp → menu name.
-- 2. Important columns
--    MENU_NAME, USER_MENU_NAME.
-- 3. How to interpret the output
--    Wrong menu after FNDLOAD = missing functions.
-- 4. What indicates a problem
--    Users missing a form that exists.
-- 5. Recommended DBA action
--    20/09 entries.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE resp_name = System Administrator
SELECT r.responsibility_name, m.menu_name, m.user_menu_name
FROM fnd_responsibility_vl r JOIN fnd_menus_vl m ON m.menu_id=r.menu_id
WHERE r.responsibility_name='&resp_name';

PROMPT
PROMPT === End of query: Menu ===
PROMPT

-- End of file
