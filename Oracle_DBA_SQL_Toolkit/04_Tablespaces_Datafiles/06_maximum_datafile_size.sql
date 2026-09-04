--------------------------------------------------------------------------------
-- File Name       : 06_maximum_datafile_size.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Explain smallfile vs bigfile maximum sizes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Smallfile tablespaces are limited by block size * 4M blocks (~32GB at 8K).
-- Attempting to extend beyond that raises ORA-01237 / ORA-03206.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Bigfile flag and current vs theoretical max
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins DBA_TABLESPACES.BIGFILE with file sizes.
-- 2. Important columns
--    BIGFILE, BLOCK_SIZE, SIZE_GB, MAX_GB.
-- 3. How to interpret the output
--    BIGFILE YES can grow very large (32TB+ depending on block size). Smallfile needs more files, not a bigger MAXSIZE.
-- 4. What indicates a problem
--    Trying to set MAXSIZE 100G on an 8K smallfile.
-- 5. Recommended DBA action
--    Add another smallfile or convert strategy to bigfile for new tablespaces only (migration is a project).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TABLESPACES, DBA_DATA_FILES
--------------------------------------------------------------------------------
SELECT
       ts.tablespace_name,
       ts.bigfile,
       ts.block_size,
       df.file_id,
       ROUND(df.bytes/1024/1024/1024,2) AS size_gb,
       ROUND(df.maxbytes/1024/1024/1024,2) AS max_gb,
       CASE WHEN ts.bigfile = 'NO' AND ts.block_size = 8192
            THEN 32 ELSE NULL END AS typical_smallfile_limit_gb
FROM   dba_tablespaces ts
JOIN   dba_data_files df ON df.tablespace_name = ts.tablespace_name
ORDER BY ts.tablespace_name, df.file_id;

PROMPT
PROMPT === End of query: Bigfile flag and current vs theoretical max ===
PROMPT

-- End of file
