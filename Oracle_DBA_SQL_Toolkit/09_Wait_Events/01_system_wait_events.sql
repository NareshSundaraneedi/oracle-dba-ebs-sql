--------------------------------------------------------------------------------
-- File Name       : 01_system_wait_events.sql
-- Category        : 09_Wait_Events
-- Purpose         : Instance-level wait event totals since startup (non-idle)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- GV$SYSTEM_EVENT since-startup totals. Good for a first look; not a
-- rate. For a time window use 08_SQL_Tuning/18 (AWR, licensed).
-- Meaning → Possible Cause → How to Investigate → Possible Fix is documented per query.
--
-- Pack-free. Difference vs 03_top_wait_events.sql: this is the full list; 03 is ranked top-N with average wait.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Non-idle system events
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$SYSTEM_EVENT excluding Idle.
-- 2. Important columns
--    EVENT, TOTAL_WAITS, TIME_WAITED_S, AVG_MS, WAIT_CLASS.
-- 3. How to interpret the output
--    TIME_WAITED is cumulative. Compare AVG_MS to your storage/commit SLOs.
-- 4. What indicates a problem
--    An event with huge TIME_WAITED that is not normally in the top 5.
-- 5. Recommended DBA action
--    Open the event-specific script in this folder.
-- 6. Production cautions
--    Safe. Since-startup bias toward events present since bounce.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT
       inst_id,
       event,
       wait_class,
       total_waits,
       total_timeouts,
       ROUND(time_waited_micro/1e6,1) AS time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) AS avg_wait_ms
FROM   gv$system_event
WHERE  wait_class <> 'Idle'
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: Non-idle system events ===
PROMPT

-- End of file
