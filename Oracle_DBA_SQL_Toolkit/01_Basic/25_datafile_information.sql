--------------------------------------------------------------------------------
-- File Name       : 25_datafile_information.sql
-- Category        : 01_Basic
-- Purpose         : List datafiles with size, autoextend, and status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- File-level view for space and backup planning. ONLINE / RECOVER
-- status problems are restore incidents.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Datafile inventory
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_DATA_FILES and V$DATAFILE for status and checkpoint.
-- 2. Important columns
--    FILE_ID, FILE_NAME, TABLESPACE_NAME, SIZE_GB, AUTOEXTENSIBLE, MAX_GB, STATUS.
-- 3. How to interpret the output
--    AVAILABLE is healthy. RECOVER means the file needs media recovery. ONLINE in DBA_DATA_FILES plus SYSOFF in V$DATAFILE is a problem.
-- 4. What indicates a problem
--    File at MAXSIZE and tablespace nearly full. STATUS RECOVER. File on a full ASM diskgroup.
-- 5. Recommended DBA action
--    Add space or recover the file with RMAN. Do not resize below HWM.
-- 6. Production cautions
--    Safe. Adding datafiles is a change.
-- 7. Required privileges
--    SELECT on DBA_DATA_FILES, V_$DATAFILE
--------------------------------------------------------------------------------
SELECT
       df.file_id,
       df.tablespace_name,
       df.file_name,
       ROUND(df.bytes / 1024 / 1024 / 1024, 2) AS size_gb,
       df.autoextensible,
       ROUND(df.maxbytes / 1024 / 1024 / 1024, 2) AS max_gb,
       df.status,
       df.online_status,
       v.status AS v_status
FROM   dba_data_files df
JOIN   v$datafile v ON v.file# = df.file_id
ORDER BY df.tablespace_name, df.file_id;

PROMPT
PROMPT === End of query: Datafile inventory ===
PROMPT

-- End of file
