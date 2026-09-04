--------------------------------------------------------------------------------
-- File Name       : 26_tempfile_information.sql
-- Category        : 01_Basic
-- Purpose         : List tempfiles and temporary tablespace configuration
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Temporary tablespaces are instance-local on RAC (each instance has
-- tempfiles). Running out of TEMP raises ORA-01652 during sorts and hash joins.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Tempfile inventory
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lists DBA_TEMP_FILES and default temporary tablespace.
-- 2. Important columns
--    FILE_NAME, TABLESPACE_NAME, SIZE_GB, AUTOEXTENSIBLE, MAX_GB.
-- 3. How to interpret the output
--    TEMP can look 'full' after a large sort and then shrink in 12c+ if it is a locally managed tempfile that shrinks — but space is reused without shrinking.
-- 4. What indicates a problem
--    Single small tempfile, autoextend NO, during month-end or Gather Schema Stats.
-- 5. Recommended DBA action
--    Add a tempfile or enable autoextend with a sane MAXSIZE. See 14_TEMP for session-level usage.
-- 6. Production cautions
--    Safe. Shrinking TEMP can be done online but is a change.
-- 7. Required privileges
--    SELECT on DBA_TEMP_FILES, DATABASE_PROPERTIES
--------------------------------------------------------------------------------
SELECT property_name, property_value
FROM   database_properties
WHERE  property_name = 'DEFAULT_TEMP_TABLESPACE';

SELECT
       file_id,
       tablespace_name,
       file_name,
       ROUND(bytes / 1024 / 1024 / 1024, 2) AS size_gb,
       autoextensible,
       ROUND(maxbytes / 1024 / 1024 / 1024, 2) AS max_gb,
       status
FROM   dba_temp_files
ORDER BY tablespace_name, file_id;

PROMPT
PROMPT === End of query: Tempfile inventory ===
PROMPT

-- End of file
