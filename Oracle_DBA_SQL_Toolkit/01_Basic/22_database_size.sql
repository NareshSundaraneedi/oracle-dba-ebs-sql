--------------------------------------------------------------------------------
-- File Name       : 22_database_size.sql
-- Category        : 01_Basic
-- Purpose         : Compute total allocated and used database size
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Gives a capacity snapshot: datafile, tempfile, redo, and control file
-- sizes. Use for clone sizing and storage requests.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Allocated size by file type
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sums DBA_DATA_FILES, DBA_TEMP_FILES, V$LOG, and V$CONTROLFILE.
-- 2. Important columns
--    FILE_TYPE, ALLOCATED_GB, USED_GB (datafiles only).
-- 3. How to interpret the output
--    Allocated is what storage sees. Used is segment occupancy and can be much lower if files are oversized.
-- 4. What indicates a problem
--    Allocated size approaching the ASM diskgroup or volume limit.
-- 5. Recommended DBA action
--    Plan datafile adds or diskgroup growth. Do not shrink datafiles as a first response.
-- 6. Production cautions
--    Safe but queries DBA views. On very large estates this is still cheap.
-- 7. Required privileges
--    SELECT on DBA_DATA_FILES, DBA_TEMP_FILES, DBA_SEGMENTS, V_$LOG, V_$CONTROLFILE
--------------------------------------------------------------------------------
SELECT
       'DATAFILES' AS file_type,
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) AS allocated_gb
FROM   dba_data_files
UNION ALL
SELECT 'TEMPFILES',
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2)
FROM   dba_temp_files
UNION ALL
SELECT 'REDO',
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2)
FROM   v$log
UNION ALL
SELECT 'CONTROLFILE',
       ROUND(SUM(block_size * file_size_blks) / 1024 / 1024 / 1024, 2)
FROM   v$controlfile;

SELECT ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) AS segment_used_gb
FROM   dba_segments;

PROMPT
PROMPT === End of query: Allocated size by file type ===
PROMPT

-- End of file
