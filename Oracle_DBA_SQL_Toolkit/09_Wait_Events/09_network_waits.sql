--------------------------------------------------------------------------------
-- File Name       : 09_network_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Network wait class (SQL*Net)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: time in SQL*Net message to/from client is often idle
-- (wait for the user). SQL*Net more data to client can be chatty fetches.
-- Cause: chatty arraysize, WAN latency, broken firewall idle timeout.
-- Investigate: distinguish more data vs message from client (Idle).
-- Fix: arraysize, reduce round trips — do not tune storage.
--
-- Pack-free. message from client is Idle and excluded from 01; shown here for completeness.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Network and SQL*Net
--------------------------------------------------------------------------------
-- 1. What the query does
--    Network class plus explicit SQL*Net events.
-- 2. Important columns
--    EVENT, TIME_S.
-- 3. How to interpret the output
--    more data to client high = large result sets or arraysize 1.
-- 4. What indicates a problem
--    WAN users with huge more data waits after a report change.
-- 5. Recommended DBA action
--    Increase arraysize / tune the report.
-- 6. Production cautions
--    Safe. Do not treat message from client as a DB problem.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, event, wait_class, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  wait_class = 'Network'
OR     event LIKE 'SQL*Net%'
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: Network and SQL*Net ===
PROMPT

-- End of file
