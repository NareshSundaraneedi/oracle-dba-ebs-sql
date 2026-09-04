--------------------------------------------------------------------------------
-- File Name       : 12_excessive_log_switches.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Flag switch storms (< 2 minutes apart)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Filters 11 for short gaps. Use during 'redo contention' or checkpoint incomplete.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Switch storm
--------------------------------------------------------------------------------
-- 1. What the query does
--    Minutes_since_prev < 2.
-- 2. Important columns
--    SEQUENCE#, MINUTES.
-- 3. How to interpret the output
--    Storms during index rebuilds or large loads are expected — reschedule.
-- 4. What indicates a problem
--    Storms during normal OLTP.
-- 5. Recommended DBA action
--    Find redo-heavy SQL (07 top physical writes / redo).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$LOG_HISTORY
--------------------------------------------------------------------------------
WITH h AS (
  SELECT thread#, sequence#, first_time,
         (first_time - LAG(first_time) OVER (PARTITION BY thread# ORDER BY sequence#))*24*60 mins
  FROM v$log_history WHERE first_time > SYSDATE-1
)
SELECT * FROM h WHERE mins < 2 ORDER BY first_time;

PROMPT
PROMPT === End of query: Switch storm ===
PROMPT

-- End of file
