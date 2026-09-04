--------------------------------------------------------------------------------
-- File Name       : 05_applsys_information.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : APPLSYS schema objects and invalids
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- APPLSYS owns FND tables. Invalid APPLSYS objects break login and concurrent processing.
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
-- QUERY 1: APPLSYS invalids and size
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_OBJECTS / DBA_SEGMENTS for APPLSYS.
-- 2. Important columns
--    INVALIDS, SIZE_GB.
-- 3. How to interpret the output
--    Zero invalids expected after a successful compile.
-- 4. What indicates a problem
--    Invalid FND packages after a failed adop fs_clone.
-- 5. Recommended DBA action
--    Compile via adadmin / adop. Do not compile APPLSYS as a random user.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_OBJECTS, DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT status, COUNT(*) FROM dba_objects WHERE owner='APPLSYS' GROUP BY status;
SELECT object_type, object_name FROM dba_objects WHERE owner='APPLSYS' AND status='INVALID' ORDER BY 1,2;
SELECT ROUND(SUM(bytes)/1024/1024/1024,2) applsys_gb FROM dba_segments WHERE owner='APPLSYS';

PROMPT
PROMPT === End of query: APPLSYS invalids and size ===
PROMPT

-- End of file
