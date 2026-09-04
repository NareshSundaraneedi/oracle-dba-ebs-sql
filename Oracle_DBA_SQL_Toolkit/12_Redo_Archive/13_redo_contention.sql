--------------------------------------------------------------------------------
-- File Name       : 13_redo_contention.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Redo allocation / copy latch and wait events
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Historical redo allocation latch is less common with private strands, but log file switch (checkpoint incomplete) and redo copy still appear.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Redo wait events
--------------------------------------------------------------------------------
-- 1. What the query does
--    System events redo/log file switch.
-- 2. Important columns
--    EVENT, TIME_S.
-- 3. How to interpret the output
--    checkpoint incomplete = DBWR cannot keep up with switches.
-- 4. What indicates a problem
--    checkpoint incomplete during switch storms.
-- 5. Recommended DBA action
--    Bigger redo + faster DBWR I/O + fewer switches.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$system_event
WHERE event LIKE 'log file%' OR event LIKE 'redo%'
ORDER BY time_waited_micro DESC;

PROMPT
PROMPT === End of query: Redo wait events ===
PROMPT

-- End of file
