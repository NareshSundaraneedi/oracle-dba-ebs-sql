--------------------------------------------------------------------------------
-- File Name       : 08_fra_usage.sql
-- Category        : 02_Database_Administration
-- Purpose         : Fast Recovery Area usage and reclaimable space
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- A full FRA suspends archiving (database hangs on log switch). This is
-- a top production check. Warning bands: 70 monitor, 85 warning, 95 critical.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: FRA size, usage, and file types
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$RECOVERY_FILE_DEST and V$FLASH_RECOVERY_AREA_USAGE (V$RECOVERY_AREA_USAGE on 11g+).
-- 2. Important columns
--    SPACE_LIMIT, SPACE_USED, SPACE_RECLAIMABLE, FILE_TYPE, PERCENT_SPACE_USED.
-- 3. How to interpret the output
--    SPACE_RECLAIMABLE is obsolete backups/archivelogs that Oracle can delete when policy allows. Used-reclaimable is the true pressure.
-- 4. What indicates a problem
--    PERCENT_SPACE_USED > 85 with little reclaimable — archive dest will soon fail.
-- 5. Recommended DBA action
--    Back up and delete archivelogs (RMAN), raise db_recovery_file_dest_size, or move obsolete backups. Do not delete FRA files at OS level.
-- 6. Production cautions
--    Safe to query. OS deletes of FRA files corrupt the FRA inventory.
-- 7. Required privileges
--    SELECT on V_$RECOVERY_FILE_DEST, V_$RECOVERY_AREA_USAGE, V_$PARAMETER
--------------------------------------------------------------------------------
SELECT name, value
FROM   v$parameter
WHERE  name IN ('db_recovery_file_dest','db_recovery_file_dest_size');

SELECT
       name,
       ROUND(space_limit / 1024 / 1024 / 1024, 2) AS limit_gb,
       ROUND(space_used / 1024 / 1024 / 1024, 2) AS used_gb,
       ROUND(space_reclaimable / 1024 / 1024 / 1024, 2) AS reclaimable_gb,
       ROUND(space_used * 100 / NULLIF(space_limit, 0), 1) AS used_pct,
       CASE
         WHEN space_used * 100 / NULLIF(space_limit, 0) > 95 THEN 'CRITICAL'
         WHEN space_used * 100 / NULLIF(space_limit, 0) > 85 THEN 'WARNING'
         WHEN space_used * 100 / NULLIF(space_limit, 0) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level,
       number_of_files
FROM   v$recovery_file_dest;

SELECT
       file_type,
       percent_space_used,
       percent_space_reclaimable,
       number_of_files
FROM   v$recovery_area_usage
ORDER BY percent_space_used DESC;

PROMPT
PROMPT === End of query: FRA size, usage, and file types ===
PROMPT

-- End of file
