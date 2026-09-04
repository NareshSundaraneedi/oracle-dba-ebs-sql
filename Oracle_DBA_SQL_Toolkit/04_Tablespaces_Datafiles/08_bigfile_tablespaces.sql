--------------------------------------------------------------------------------
-- File Name       : 08_bigfile_tablespaces.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : List bigfile tablespaces and their single datafile
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Bigfile tablespaces have exactly one datafile. RMAN and file ops
-- differ (you resize the tablespace, not add files).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Bigfile tablespaces
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters DBA_TABLESPACES.BIGFILE = YES.
-- 2. Important columns
--    TABLESPACE_NAME, FILE_NAME, SIZE_GB.
-- 3. How to interpret the output
--    One file per TS. Space issues are resolved with ALTER TABLESPACE ... RESIZE.
-- 4. What indicates a problem
--    Bigfile on a file system with a 16TB file size limit approaching the cap.
-- 5. Recommended DBA action
--    Plan storage. Do not add a second datafile to a bigfile tablespace — it will fail.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TABLESPACES, DBA_DATA_FILES
--------------------------------------------------------------------------------
SELECT
       ts.tablespace_name,
       ts.status,
       ts.contents,
       df.file_name,
       ROUND(df.bytes/1024/1024/1024,2) AS size_gb,
       df.autoextensible
FROM   dba_tablespaces ts
JOIN   dba_data_files df ON df.tablespace_name = ts.tablespace_name
WHERE  ts.bigfile = 'YES'
ORDER BY ts.tablespace_name;

PROMPT
PROMPT === End of query: Bigfile tablespaces ===
PROMPT

-- End of file
