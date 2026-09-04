--------------------------------------------------------------------------------
-- File Name       : 07_sql_patches.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : List SQL patches (hint-based)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SQL patches (DBMS_SQLDIAG_INTERNAL / DBMS_SQLPATCH in 19c
-- DBMS_SQLDIAG.CREATE_SQL_PATCH) attach hints without changing text.
-- Used as a tactical fix.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL patches
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_SQL_PATCHES.
-- 2. Important columns
--    NAME, STATUS, SQL_TEXT.
-- 3. How to interpret the output
--    ENABLED patches apply hints. They are easy to forget after the root cause is fixed.
-- 4. What indicates a problem
--    Conflicting patch + profile + baseline on the same SQL_ID.
-- 5. Recommended DBA action
--    Keep one control mechanism. Disable extras with approval.
-- 6. Production cautions
--    Safe to list.
-- 7. Required privileges
--    SELECT on DBA_SQL_PATCHES
--------------------------------------------------------------------------------
SELECT name, category, status, force_matching, created, SUBSTR(sql_text,1,200) sql_text
FROM   dba_sql_patches
ORDER BY created DESC;

PROMPT
PROMPT === End of query: SQL patches ===
PROMPT

-- End of file
