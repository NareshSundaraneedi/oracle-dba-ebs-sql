--------------------------------------------------------------------------------
-- File Name       : 05_autoextend_status.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : List files with autoextend off or unlimited maxsize
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- UNLIMITED autoextend can fill an ASM diskgroup without a tablespace
-- alert firing at 85% allocated.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Autoextend anomalies
--------------------------------------------------------------------------------
-- 1. What the query does
--    Flags AUTOEXTENSIBLE NO and MAXBYTES at the platform unlimited sentinel.
-- 2. Important columns
--    FILE_NAME, AUTOEXTENSIBLE, MAXBYTES.
-- 3. How to interpret the output
--    MAXBYTES of 34359721984 (32GB-ish) is the typical smallfile ceiling, not unlimited. 0 or huge values need review.
-- 4. What indicates a problem
--    Autoextend ON MAXSIZE UNLIMITED on a diskgroup that is already 80% full.
-- 5. Recommended DBA action
--    Set a finite MAXSIZE and monitor diskgroup space.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_DATA_FILES, DBA_TEMP_FILES
--------------------------------------------------------------------------------
SELECT 'DATA' AS file_kind, file_id, tablespace_name, autoextensible,
       ROUND(bytes/1024/1024/1024,2) size_gb,
       ROUND(maxbytes/1024/1024/1024,2) max_gb
FROM   dba_data_files
WHERE  autoextensible = 'NO'
OR     maxbytes = 0
OR     maxbytes >= 32*1024*1024*1024
UNION ALL
SELECT 'TEMP', file_id, tablespace_name, autoextensible,
       ROUND(bytes/1024/1024/1024,2),
       ROUND(maxbytes/1024/1024/1024,2)
FROM   dba_temp_files
WHERE  autoextensible = 'NO'
OR     maxbytes = 0
ORDER BY 1, 3, 2;

PROMPT
PROMPT === End of query: Autoextend anomalies ===
PROMPT

-- End of file
