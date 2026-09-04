--------------------------------------------------------------------------------
-- File Name       : 01_invalid_objects.sql
-- Category        : 05_Objects
-- Purpose         : Invalid objects with dependency hints
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Deeper than 01_Basic/28: includes last DDL and a generated compile
-- command. Compiling is a change and can lock objects.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Invalid objects and compile command
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lists INVALID objects and generates ALTER ... COMPILE.
-- 2. Important columns
--    OWNER, OBJECT_TYPE, OBJECT_NAME, LAST_DDL_TIME.
-- 3. How to interpret the output
--    Invalid SYNONYM often means the target is missing after a clone.
-- 4. What indicates a problem
--    Invalid APPS packages after a patch. Invalid SYS after datapatch failure.
-- 5. Recommended DBA action
--    Use utlrp.sql as SYS for catalog. For EBS use adop/adadmin compile. Generated ALTER is for non-SYS custom objects only after approval.
-- 6. Production cautions
--    WARNING: COMPILE locks the object and dependents. Generated only. Never compile SYS/SYSTEM ad hoc.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT owner, object_type, COUNT(*) invalids
FROM   dba_objects
WHERE  status = 'INVALID'
GROUP BY owner, object_type
ORDER BY invalids DESC;

SELECT
       owner,
       object_type,
       object_name,
       last_ddl_time
FROM   dba_objects
WHERE  status = 'INVALID'
ORDER BY owner, object_type, object_name;

-- WARNING: Review carefully. Do not compile SYS/SYSTEM.
SELECT
       CASE object_type
         WHEN 'PACKAGE BODY' THEN 'ALTER PACKAGE "'||owner||'"."'||object_name||'" COMPILE BODY;'
         WHEN 'PACKAGE'      THEN 'ALTER PACKAGE "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'PROCEDURE'    THEN 'ALTER PROCEDURE "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'FUNCTION'     THEN 'ALTER FUNCTION "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'VIEW'         THEN 'ALTER VIEW "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'TRIGGER'      THEN 'ALTER TRIGGER "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'SYNONYM'      THEN 'ALTER SYNONYM "'||owner||'"."'||object_name||'" COMPILE;'
         ELSE '-- skip '||object_type||' '||owner||'.'||object_name
       END AS compile_cmd
FROM   dba_objects
WHERE  status = 'INVALID'
AND    owner NOT IN ('SYS','SYSTEM','XDB');

PROMPT
PROMPT === End of query: Invalid objects and compile command ===
PROMPT

-- End of file
