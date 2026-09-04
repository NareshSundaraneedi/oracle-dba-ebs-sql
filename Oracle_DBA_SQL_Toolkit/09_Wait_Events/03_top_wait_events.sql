--------------------------------------------------------------------------------
-- File Name       : 03_top_wait_events.sql
-- Category        : 09_Wait_Events
-- Purpose         : Top 20 non-idle wait events with average wait
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Daily/incident ranked wait view.
--
-- Pack-free.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top waits
--------------------------------------------------------------------------------
-- 1. What the query does
--    Top 20 from GV$SYSTEM_EVENT.
-- 2. Important columns
--    EVENT, TIME_WAITED_S, AVG_MS.
-- 3. How to interpret the output
--    High TIME with low AVG = many short waits (chatty). High AVG = latency.
-- 4. What indicates a problem
--    avg_wait_ms for log file sync > 10ms on decent storage, or gc waits dominating a well-sized RAC.
-- 5. Recommended DBA action
--    Event-specific file.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT
       inst_id,
       event,
       wait_class,
       total_waits,
       ROUND(time_waited_micro/1e6,1) AS time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) AS avg_wait_ms
FROM   gv$system_event
WHERE  wait_class <> 'Idle'
ORDER BY time_waited_micro DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: Top waits ===
PROMPT

-- End of file
