--------------------------------------------------------------------------------
-- File Name       : 08_database_uptime.sql
-- Category        : 01_Basic
-- Purpose         : Calculate instance uptime in days, hours, and minutes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Human-readable uptime. Use during capacity reviews and after patching
-- to confirm the instance stayed up.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Formatted instance uptime
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes days/hours/minutes since STARTUP_TIME.
-- 2. Important columns
--    INST_ID, STARTUP_TIME, DAYS, HOURS, MINUTES.
-- 3. How to interpret the output
--    Short uptime after a planned bounce is expected. Short uptime without a change record is an incident.
-- 4. What indicates a problem
--    Repeated short uptimes indicate instability (memory, clusterware, storage).
-- 5. Recommended DBA action
--    If unplanned, pull alert log, OS messages, and Clusterware logs for the restart time.
-- 6. Production cautions
--    Safe. Does not include database MOUNT time separately from OPEN.
-- 7. Required privileges
--    SELECT on GV_$INSTANCE
--------------------------------------------------------------------------------
SELECT
       inst_id,
       instance_name,
       startup_time,
       TRUNC(SYSDATE - startup_time) AS days,
       TRUNC(MOD((SYSDATE - startup_time) * 24, 24)) AS hours,
       TRUNC(MOD((SYSDATE - startup_time) * 24 * 60, 60)) AS minutes,
       ROUND((SYSDATE - startup_time) * 24, 2) AS total_hours
FROM   gv$instance
ORDER BY inst_id;

PROMPT
PROMPT === End of query: Formatted instance uptime ===
PROMPT

-- End of file
