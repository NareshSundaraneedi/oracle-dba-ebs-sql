--------------------------------------------------------------------------------
-- File Name       : 09_gc_current_requests.sql
-- Category        : 15_RAC
-- Purpose         : GC current (DML) traffic
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Current-mode transfers are more expensive than CR. Hot index leaves and sequences show up here.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Current events
--------------------------------------------------------------------------------
-- 1. What the query does
--    gc current% + sysstat.
-- 2. Important columns
--    EVENT, TIME_S.
-- 3. How to interpret the output
--    Current 2-way/3-way grants vs blocks.
-- 4. What indicates a problem
--    gc current block busy on a sequence-driven PK.
-- 5. Recommended DBA action
--    Increase sequence cache; localize DML via services.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT inst_id, event, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$system_event WHERE event LIKE 'gc current%'
ORDER BY time_s DESC;

PROMPT
PROMPT === End of query: Current events ===
PROMPT

-- End of file
