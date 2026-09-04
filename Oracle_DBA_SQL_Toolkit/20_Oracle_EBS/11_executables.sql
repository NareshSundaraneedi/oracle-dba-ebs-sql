--------------------------------------------------------------------------------
-- File Name       : 11_executables.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Concurrent executables (spawn, PL/SQL, host, java)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_EXECUTABLES — execution_method_code I=PL/SQL, P=Oracle Reports, H=Host, K=Java, etc.
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
-- QUERY 1: Executable lookup
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_EXECUTABLES_VL.
-- 2. Important columns
--    EXECUTABLE_NAME, EXECUTION_FILE_NAME, METHOD.
-- 3. How to interpret the output
--    Wrong EXECUTION_FILE_NAME after a clone (path still pointing at source).
-- 4. What indicates a problem
--    Host executable path invalid — program stays Running or goes Error immediately.
-- 5. Recommended DBA action
--    Fix via the Executable form / $CUSTOM_TOP.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE exec_p = %XX%

SELECT executable_name, user_executable_name, execution_method_code,
       execution_file_name, execution_file_path, application_id
FROM fnd_executables_vl
WHERE executable_name LIKE '&exec_p'
   OR user_executable_name LIKE '&exec_p'
ORDER BY executable_name;

PROMPT
PROMPT === End of query: Executable lookup ===
PROMPT

-- End of file
