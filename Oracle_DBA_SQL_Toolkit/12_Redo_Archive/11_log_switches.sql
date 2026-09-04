--------------------------------------------------------------------------------
-- File Name       : 11_log_switches.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Log switch history from V$LOG_HISTORY
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$LOG_HISTORY is switch history (control file).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Recent switches
--------------------------------------------------------------------------------
-- 1. What the query does
--    Last 200 switches.
-- 2. Important columns
--    SEQUENCE#, FIRST_TIME.
-- 3. How to interpret the output
--    Compute minutes between switches.
-- 4. What indicates a problem
--    Many switches < 1 minute apart.
-- 5. Recommended DBA action
--    12 and 05. Increase redo size.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$LOG_HISTORY
--------------------------------------------------------------------------------
SELECT thread#, sequence#, first_time,
       ROUND((first_time - LAG(first_time) OVER (PARTITION BY thread# ORDER BY sequence#))*24*60,1) minutes_since_prev
FROM v$log_history
WHERE first_time > SYSDATE-1
ORDER BY thread#, sequence#;

PROMPT
PROMPT === End of query: Recent switches ===
PROMPT

-- End of file
