--------------------------------------------------------------------------------
-- File Name       : 14_forms.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Forms and form functions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_FORM + FND_FORM_FUNCTIONS. Diagnose FRM-40010 / function not found.
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
-- QUERY 1: Form function lookup
--------------------------------------------------------------------------------
-- 1. What the query does
--    Search functions/forms.
-- 2. Important columns
--    FUNCTION_NAME, FORM_NAME, PARAMETERS.
-- 3. How to interpret the output
--    PARAMETERS often include query-only flags.
-- 4. What indicates a problem
--    Function missing after FNDLOAD to a clone.
-- 5. Recommended DBA action
--    Reload ldt. Compile form on the apps tier (not SQL).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE fname = %FNDSCSGN%

SELECT ff.function_name, ff.user_function_name, f.form_name, f.user_form_name, ff.parameters
FROM fnd_form_functions_vl ff
LEFT JOIN fnd_form_vl f ON f.form_id = ff.form_id AND f.application_id = ff.application_id
WHERE ff.function_name LIKE '&fname'
   OR f.form_name LIKE '&fname'
   OR ff.user_function_name LIKE '&fname';

PROMPT
PROMPT === End of query: Form function lookup ===
PROMPT

-- End of file
