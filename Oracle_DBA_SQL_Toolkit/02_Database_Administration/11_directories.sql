--------------------------------------------------------------------------------
-- File Name       : 11_directories.sql
-- Category        : 02_Database_Administration
-- Purpose         : List Oracle directory objects and who can write them
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Directories are used by Datapump, BFILE, and EBS concurrent programs
-- that write OS files. A wrong path after a clone is a common outage.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Directories and grants
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_DIRECTORIES and DBA_TAB_PRIVS for directory grants.
-- 2. Important columns
--    DIRECTORY_NAME, DIRECTORY_PATH, GRANTEE, PRIVILEGE.
-- 3. How to interpret the output
--    APPS typically needs READ/WRITE on several utl_file directories.
-- 4. What indicates a problem
--    Path pointing at the source environment after a clone. PUBLIC WRITE on a sensitive path.
-- 5. Recommended DBA action
--    CREATE OR REPLACE DIRECTORY in a change window. Fix grants to least privilege.
-- 6. Production cautions
--    Safe. Creating directories is a change and requires OS path existence.
-- 7. Required privileges
--    SELECT on DBA_DIRECTORIES, DBA_TAB_PRIVS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT directory_name, directory_path
FROM   dba_directories
ORDER BY directory_name;

SELECT
       p.grantee,
       p.table_name AS directory_name,
       p.privilege,
       p.grantable
FROM   dba_tab_privs p
JOIN   dba_directories d ON d.directory_name = p.table_name
WHERE  p.privilege IN ('READ','WRITE','EXECUTE')
ORDER BY p.table_name, p.grantee, p.privilege;

PROMPT
PROMPT === End of query: Directories and grants ===
PROMPT

-- End of file
