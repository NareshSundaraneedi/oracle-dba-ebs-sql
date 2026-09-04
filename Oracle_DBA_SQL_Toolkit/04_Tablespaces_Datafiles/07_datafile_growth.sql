--------------------------------------------------------------------------------
-- File Name       : 07_datafile_growth.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Show files that autoextended recently via alert or file size vs creation
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$DATAFILE.CREATE_BYTES vs BYTES shows growth since file creation.
-- For a time series, use AWR (licensed) or compare weekly snapshots.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Datafile growth since creation
--------------------------------------------------------------------------------
-- 1. What the query does
--    Compares V$DATAFILE.BYTES to CREATE_BYTES.
-- 2. Important columns
--    FILE_NAME, CREATE_GB, CURRENT_GB, GROWN_GB.
-- 3. How to interpret the output
--    Large GROWN_GB on a recently added file means rapid load.
-- 4. What indicates a problem
--    A file created yesterday already at MAXSIZE.
-- 5. Recommended DBA action
--    Find the segment. Add space before the next batch window.
-- 6. Production cautions
--    Safe. CREATE_BYTES is since the file was created, not since last week.
-- 7. Required privileges
--    SELECT on V_$DATAFILE, DBA_DATA_FILES
--------------------------------------------------------------------------------
SELECT
       d.file_id,
       d.tablespace_name,
       d.file_name,
       ROUND(v.create_bytes/1024/1024/1024,2) AS create_gb,
       ROUND(v.bytes/1024/1024/1024,2) AS current_gb,
       ROUND((v.bytes - v.create_bytes)/1024/1024/1024,2) AS grown_gb
FROM   dba_data_files d
JOIN   v$datafile v ON v.file# = d.file_id
ORDER BY grown_gb DESC;

PROMPT
PROMPT === End of query: Datafile growth since creation ===
PROMPT

-- End of file
