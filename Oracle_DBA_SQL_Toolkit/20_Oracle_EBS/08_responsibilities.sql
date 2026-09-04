--------------------------------------------------------------------------------
-- File Name       : 08_responsibilities.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Responsibility inventory
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_RESPONSIBILITY_VL. Folder 27 has user-to-resp assignments.
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
-- QUERY 1: Responsibilities
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_RESPONSIBILITY_VL.
-- 2. Important columns
--    RESPONSIBILITY_NAME, APPLICATION, END_DATE, DATA_GROUP.
-- 3. How to interpret the output
--    End-dated responsibilities should not be assigned to new users.
-- 4. What indicates a problem
--    A custom responsibility missing after clone (data group / request group not imported).
-- 5. Recommended DBA action
--    Recreate via form or FNDLOAD — not INSERT.
-- 6. Production cautions
--    Safe. Result can be large — first 200.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT responsibility_id, responsibility_name, application_id, start_date, end_date,
       data_group_id, menu_id, request_group_id
FROM fnd_responsibility_vl
ORDER BY responsibility_name
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Responsibilities ===
PROMPT

-- End of file
