--------------------------------------------------------------------------------
-- File Name       : 14_object_modifications.sql
-- Category        : 05_Objects
-- Purpose         : Objects with recent LAST_DDL_TIME
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds what changed recently — useful after an unexplained break.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: DDL in the last 7 days (non-Oracle schemas)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_OBJECTS by LAST_DDL_TIME.
-- 2. Important columns
--    OWNER, OBJECT_NAME, OBJECT_TYPE, LAST_DDL_TIME.
-- 3. How to interpret the output
--    Compile-only DDL still updates LAST_DDL_TIME.
-- 4. What indicates a problem
--    A production package changed with no ticket.
-- 5. Recommended DBA action
--    Diff against source control / EBS patch history.
-- 6. Production cautions
--    Safe. EBS patching will produce a large result — tighten the window.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS, DBA_USERS
--------------------------------------------------------------------------------
SELECT o.owner, o.object_type, o.object_name, o.last_ddl_time, o.status
FROM   dba_objects o
JOIN   dba_users u ON u.username = o.owner
WHERE  u.oracle_maintained = 'N'
AND    o.last_ddl_time > SYSDATE - 7
ORDER BY o.last_ddl_time DESC;

PROMPT
PROMPT === End of query: DDL in the last 7 days (non-Oracle schemas) ===
PROMPT

-- End of file
