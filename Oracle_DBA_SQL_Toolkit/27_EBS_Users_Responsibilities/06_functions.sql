--------------------------------------------------------------------------------
-- File Name       : 06_functions.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Functions a user can reach (via one responsibility menu — not exclusions)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Does not expand all nested menus recursively (that is a connect-by). Lists entries on the top menu.
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
-- QUERY 1: Top-level functions
--------------------------------------------------------------------------------
-- 1. What the query does
--    Menu entries for the resp menu.
-- 2. Important columns
--    PROMPT, FUNCTION_NAME.
-- 3. How to interpret the output
--    Exclusions (FND_RESP_FUNCTIONS) can hide these — check 10.
-- 4. What indicates a problem
--    Function present but excluded.
-- 5. Recommended DBA action
--    Function security.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE resp_name = System Administrator
SELECT e.prompt, f.function_name, f.user_function_name
FROM fnd_responsibility_vl r
JOIN fnd_menu_entries_vl e ON e.menu_id=r.menu_id
LEFT JOIN fnd_form_functions_vl f ON f.function_id=e.function_id
WHERE r.responsibility_name='&resp_name'
ORDER BY e.entry_sequence;

PROMPT
PROMPT === End of query: Top-level functions ===
PROMPT

-- End of file
