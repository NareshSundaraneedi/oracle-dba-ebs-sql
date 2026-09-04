--------------------------------------------------------------------------------
-- File Name       : 10_archive_generation.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Archive generation per hour (capacity)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Hourly histogram for RMAN backup window and FRA sizing.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Archives per hour
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group V$ARCHIVED_LOG by hour.
-- 2. Important columns
--    HOUR, MB, COUNT.
-- 3. How to interpret the output
--    Month-end hours should be in the capacity plan.
-- 4. What indicates a problem
--    A 10x spike hour — investigate redo-heavy batch.
-- 5. Recommended DBA action
--    Size FRA and redo for that hour.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVED_LOG
--------------------------------------------------------------------------------
SELECT TO_CHAR(first_time,'DD-MON HH24') hr,
       COUNT(*) logs,
       ROUND(SUM(blocks*block_size)/1024/1024,1) mb
FROM v$archived_log
WHERE first_time > SYSDATE-3 AND dest_id=1
GROUP BY TO_CHAR(first_time,'DD-MON HH24')
ORDER BY MIN(first_time);

PROMPT
PROMPT === End of query: Archives per hour ===
PROMPT

-- End of file
