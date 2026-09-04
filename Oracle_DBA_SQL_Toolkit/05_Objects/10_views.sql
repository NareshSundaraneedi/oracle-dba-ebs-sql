--------------------------------------------------------------------------------
-- File Name       : 10_views.sql
-- Category        : 05_Objects
-- Purpose         : List invalid views and view dependency counts
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Invalid views break APIs and concurrent programs that query them.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Invalid views
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_OBJECTS / DBA_VIEWS for INVALID.
-- 2. Important columns
--    OWNER, VIEW_NAME, TEXT_LENGTH.
-- 3. How to interpret the output
--    TEXT_LENGTH huge views are often generated EBS views — compile via EBS tools.
-- 4. What indicates a problem
--    Custom view INVALID after an underlying table column drop.
-- 5. Recommended DBA action
--    Compile or recreate from source control.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_VIEWS, DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT o.owner, o.object_name, o.last_ddl_time, v.text_length
FROM   dba_objects o
JOIN   dba_views v ON v.owner = o.owner AND v.view_name = o.object_name
WHERE  o.object_type = 'VIEW'
AND    o.status = 'INVALID'
ORDER BY o.owner, o.object_name;

PROMPT
PROMPT === End of query: Invalid views ===
PROMPT

-- End of file
