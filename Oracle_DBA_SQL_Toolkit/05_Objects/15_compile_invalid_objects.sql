--------------------------------------------------------------------------------
-- File Name       : 15_compile_invalid_objects.sql
-- Category        : 05_Objects
-- Purpose         : Guided compile approach (utlrp / DBMS_UTILITY) without auto-executing
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Explains the safe compile path. The script only generates calls.
-- SYS.UTLRP is the supported catalog compile.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Generated compile helpers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Prints recommended compile methods; does not execute utlrp.
-- 2. Important columns
--    GUIDANCE.
-- 3. How to interpret the output
--    Use utlrp.sql connected as SYS after patches. For a single custom package, use ALTER PACKAGE COMPILE.
-- 4. What indicates a problem
--    Looping compiles that never go valid — missing privilege or missing object.
-- 5. Recommended DBA action
--    Fix the first error in DBA_ERRORS, do not blindly loop.
-- 6. Production cautions
--    WARNING: Do not run utlrp during peak on a busy OLTP system without a window.
-- 7. Required privileges
--    SELECT on DBA_ERRORS, DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT owner, name, type, line, position, text
FROM   dba_errors
WHERE  owner NOT IN ('SYS','SYSTEM')
ORDER BY owner, name, sequence;

PROMPT Recommended (run manually as SYS after a patch window):
PROMPT   @$ORACLE_HOME/rdbms/admin/utlrp.sql
PROMPT
PROMPT For EBS application objects prefer:
PROMPT   adop phase=apply (compile) or adadmin compile apps schema
PROMPT
-- WARNING: Review carefully. Example only, not executed.
-- EXEC DBMS_UTILITY.COMPILE_SCHEMA('XXCUST', FALSE);

PROMPT
PROMPT === End of query: Generated compile helpers ===
PROMPT

-- End of file
