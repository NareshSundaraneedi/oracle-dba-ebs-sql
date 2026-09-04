--------------------------------------------------------------------------------
-- File Name       : 07_startup_time.sql
-- Category        : 01_Basic
-- Purpose         : Show instance startup time
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Returns when the instance last started. Use it to correlate incidents
-- with bounces, crashes, or patch windows.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Startup time per instance
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads STARTUP_TIME from GV$INSTANCE.
-- 2. Important columns
--    INST_ID, INSTANCE_NAME, STARTUP_TIME.
-- 3. How to interpret the output
--    A recent startup after an unexplained outage usually indicates a crash or ORA-600 bounce.
-- 4. What indicates a problem
--    Unexpected restart. On RAC, one instance restarting while others stay up points to a local node issue.
-- 5. Recommended DBA action
--    Check alert log around STARTUP_TIME for ORA-00600/07445, instance eviction, or ORA-29740.
-- 6. Production cautions
--    Safe. Startup time resets AWR baseline comparisons unless you use a preserved snapshot set.
-- 7. Required privileges
--    SELECT on GV_$INSTANCE
--------------------------------------------------------------------------------
SELECT
       inst_id,
       instance_name,
       startup_time,
       ROUND((SYSDATE - startup_time) * 24, 2) AS hours_up
FROM   gv$instance
ORDER BY inst_id;

PROMPT
PROMPT === End of query: Startup time per instance ===
PROMPT

-- End of file
