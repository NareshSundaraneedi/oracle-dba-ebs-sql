--------------------------------------------------------------------------------
-- File Name       : 03_responsibilities.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : All responsibilities with application and request group
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_RESPONSIBILITY_VL inventory.
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
-- QUERY 1: Responsibilities
--------------------------------------------------------------------------------
-- 1. What the query does
--    VL view.
-- 2. Important columns
--    RESPONSIBILITY_NAME, END_DATE, REQUEST_GROUP_ID.
-- 3. How to interpret the output
--    End-dated resp should not be newly assigned.
-- 4. What indicates a problem
--    Custom resp missing request group after clone.
-- 5. Recommended DBA action
--    FNDLOAD / form.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT responsibility_name, application_id, start_date, end_date, request_group_id, menu_id, data_group_id
FROM fnd_responsibility_vl ORDER BY responsibility_name FETCH FIRST 300 ROWS ONLY;

PROMPT
PROMPT === End of query: Responsibilities ===
PROMPT

-- End of file
