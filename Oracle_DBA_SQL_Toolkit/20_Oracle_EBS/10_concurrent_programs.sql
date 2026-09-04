--------------------------------------------------------------------------------
-- File Name       : 10_concurrent_programs.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Concurrent program definitions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_CONCURRENT_PROGRAMS_VL — executable, run-alone, enabled. Difference vs folder 22: this is metadata, not runtime requests.
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
-- QUERY 1: Programs matching a name
--------------------------------------------------------------------------------
-- 1. What the query does
--    Search by program name.
-- 2. Important columns
--    CONCURRENT_PROGRAM_NAME, USER_CONCURRENT_PROGRAM_NAME, ENABLED, EXECUTABLE.
-- 3. How to interpret the output
--    ENABLED_FLAG N explains why users cannot submit.
-- 4. What indicates a problem
--    Program missing after a patch (custom XX overwritten).
-- 5. Recommended DBA action
--    Restore from FNDLOAD ldt. Do not insert into FND_CONCURRENT_PROGRAMS.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE prog = %Gather%

SELECT fcp.concurrent_program_name, fcp.user_concurrent_program_name,
       fcp.enabled_flag, fcp.run_alone_flag, fcp.execution_method_code,
       fe.executable_name, fa.application_short_name
FROM fnd_concurrent_programs_vl fcp
JOIN fnd_executables fe ON fe.executable_id = fcp.executable_id AND fe.application_id = fcp.executable_application_id
JOIN fnd_application fa ON fa.application_id = fcp.application_id
WHERE fcp.user_concurrent_program_name LIKE '&prog'
   OR fcp.concurrent_program_name LIKE '&prog'
ORDER BY fcp.user_concurrent_program_name
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: Programs matching a name ===
PROMPT

-- End of file
