--------------------------------------------------------------------------------
-- File Name       : 28_invalid_objects.sql
-- Category        : 01_Basic
-- Purpose         : List invalid objects by owner
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Invalid packages, views, and synonyms break EBS concurrent programs
-- and Forms. After patching, expect some invalids — they should compile
-- cleanly with utlrp / adop compile.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Invalid objects summary and detail
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_OBJECTS where STATUS = INVALID.
-- 2. Important columns
--    OWNER, OBJECT_TYPE, OBJECT_NAME, LAST_DDL_TIME.
-- 3. How to interpret the output
--    A few invalids in unused schemas may be ignorable. Invalids in APPS, GL, or XX custom code are not.
-- 4. What indicates a problem
--    Sudden jump after a patch or import. SYS/SYSTEM invalids after a failed RU.
-- 5. Recommended DBA action
--    Compile with utlrp.sql (SYS) or adodfcmp / adop compile for EBS. Do not compile SYS objects ad hoc during production hours without a plan.
-- 6. Production cautions
--    Safe to query. Compiling APPS packages can invalidate dependents and lock objects — do that in a window.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT owner, object_type, COUNT(*) AS invalid_count
FROM   dba_objects
WHERE  status = 'INVALID'
GROUP BY owner, object_type
ORDER BY invalid_count DESC, owner, object_type;

SELECT
       owner,
       object_type,
       object_name,
       last_ddl_time
FROM   dba_objects
WHERE  status = 'INVALID'
ORDER BY owner, object_type, object_name;

PROMPT
PROMPT === End of query: Invalid objects summary and detail ===
PROMPT

-- End of file
