--------------------------------------------------------------------------------
-- File Name       : 04_datafile_usage.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Per-datafile allocated size and autoextend remaining
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- File-level remaining growth. Complements tablespace totals when one
-- file is at MAXSIZE and others are not.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Datafile headroom
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes remaining bytes to MAXSIZE per file.
-- 2. Important columns
--    FILE_NAME, SIZE_GB, MAX_GB, REMAINING_GB, AUTOEXTENSIBLE.
-- 3. How to interpret the output
--    AUTOEXTENSIBLE NO and tablespace 90% full means you must add a file, not wait for extend.
-- 4. What indicates a problem
--    Remaining_GB < 1 on the only file in a tablespace.
-- 5. Recommended DBA action
--    ALTER DATABASE DATAFILE ... AUTOEXTEND ON NEXT 1G MAXSIZE ... or add a file. Generated only.
-- 6. Production cautions
--    WARNING: ALTER DATABASE DATAFILE generated only. MAXSIZE is limited by file system / ASM and BIGFILE vs smallfile (32GB typical smallfile 8k).
-- 7. Required privileges
--    SELECT on DBA_DATA_FILES
--------------------------------------------------------------------------------
SELECT
       file_id,
       tablespace_name,
       file_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb,
       autoextensible,
       ROUND(maxbytes/1024/1024/1024,2) AS max_gb,
       ROUND(DECODE(autoextensible,'YES',maxbytes-bytes,0)/1024/1024/1024,2) AS remaining_gb,
       CASE
         WHEN autoextensible = 'NO' THEN 'NO_AUTOEXTEND'
         WHEN maxbytes - bytes < 1024*1024*1024 THEN 'CRITICAL'
         WHEN maxbytes - bytes < 5*1024*1024*1024 THEN 'WARNING'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_data_files
ORDER BY remaining_gb, tablespace_name;

PROMPT
PROMPT === End of query: Datafile headroom ===
PROMPT

-- End of file
