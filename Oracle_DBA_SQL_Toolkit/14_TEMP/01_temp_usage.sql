--------------------------------------------------------------------------------
-- File Name       : 01_temp_usage.sql
-- Category        : 14_TEMP
-- Purpose         : Temporary tablespace fill level
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Instance TEMP usage. Alert bands on used/total.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: TEMP free space
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_TEMP_FREE_SPACE + sort segment.
-- 2. Important columns
--    TOTAL_GB, FREE_GB, USED_PCT, ALERT.
-- 3. How to interpret the output
--    <70 Normal, 70-85 Monitor, 85-95 Warning, >95 Critical.
-- 4. What indicates a problem
--    CRITICAL during a hash join — ORA-01652 imminent.
-- 5. Recommended DBA action
--    Find session (02). Add tempfile if legitimately undersized.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TEMP_FREE_SPACE, GV_$SORT_SEGMENT
--------------------------------------------------------------------------------
SELECT tablespace_name,
       ROUND(tablespace_size/1024/1024/1024,2) total_gb,
       ROUND(free_space/1024/1024/1024,2) free_gb,
       ROUND((tablespace_size-free_space)*100/NULLIF(tablespace_size,0),1) used_pct,
       CASE
         WHEN (tablespace_size-free_space)*100/NULLIF(tablespace_size,0) > 95 THEN 'CRITICAL'
         WHEN (tablespace_size-free_space)*100/NULLIF(tablespace_size,0) > 85 THEN 'WARNING'
         WHEN (tablespace_size-free_space)*100/NULLIF(tablespace_size,0) > 70 THEN 'MONITOR'
         ELSE 'NORMAL' END alert_level
FROM dba_temp_free_space;

PROMPT
PROMPT === End of query: TEMP free space ===
PROMPT

-- End of file
