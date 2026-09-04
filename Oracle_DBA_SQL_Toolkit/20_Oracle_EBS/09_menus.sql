--------------------------------------------------------------------------------
-- File Name       : 09_menus.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Menus and menu entries for a responsibility
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Diagnose 'function not available' by walking MENU_ID from the responsibility.
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
-- QUERY 1: Menu tree for one responsibility
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins FND_RESPONSIBILITY_VL to FND_MENUS and FND_MENU_ENTRIES_VL.
-- 2. Important columns
--    MENU_NAME, PROMPT, FUNCTION_NAME.
-- 3. How to interpret the output
--    Missing prompt/function = menu not compiled or entry excluded.
-- 4. What indicates a problem
--    Users cannot see a form that exists — often menu or exclusion.
-- 5. Recommended DBA action
--    Use Function Security / Menu form. Compile menus after FNDLOAD.
-- 6. Production cautions
--    Safe. Bind responsibility name.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE resp_name = System Administrator

SELECT r.responsibility_name, m.menu_name, m.user_menu_name,
       e.entry_sequence, e.prompt, f.function_name, f.user_function_name
FROM fnd_responsibility_vl r
JOIN fnd_menus_vl m ON m.menu_id = r.menu_id
LEFT JOIN fnd_menu_entries_vl e ON e.menu_id = m.menu_id
LEFT JOIN fnd_form_functions_vl f ON f.function_id = e.function_id
WHERE r.responsibility_name = '&resp_name'
ORDER BY e.entry_sequence;

PROMPT
PROMPT === End of query: Menu tree for one responsibility ===
PROMPT

-- End of file
