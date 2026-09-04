--------------------------------------------------------------------------------
-- File Name       : 14_buffer_busy_waits.sql
-- Category        : 09_Wait_Events
-- Purpose         : Buffer busy waits and hot segments
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Meaning: session needs a buffer that is busy (another session is
-- reading or modifying it).
-- Cause: hot tail of an index, small table concurrent DML, undo header, segment header.
-- Investigate: V$SEGMENT_STATISTICS buffer busy waits, ASH p1/p2 file# block#.
-- Fix: reverse/hash, increase sequence cache, partition, PCTFREE — application design.
--
-- Pack-free for segment stats.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Buffer busy and hot segments
--------------------------------------------------------------------------------
-- 1. What the query does
--    System event + DBA_HIST optional skipped; uses V$SEGMENT_STATISTICS.
-- 2. Important columns
--    OBJECT, BUFFER_BUSY_WAITS.
-- 3. How to interpret the output
--    The object with the highest buffer busy waits is the hot segment.
-- 4. What indicates a problem
--    A custom sequence-driven PK index leaf is hot.
-- 5. Recommended DBA action
--    Increase sequence cache / reverse key only with a design review.
-- 6. Production cautions
--    Safe. V$SEGSTAT is cheap enough with a filter.
-- 7. Required privileges
--    SELECT on GV_$SYSTEM_EVENT, V_$SEGMENT_STATISTICS, DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT inst_id, event, total_waits, ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  event IN ('buffer busy waits','read by other session','latch: cache buffers chains');

SELECT
       o.owner,
       o.object_name,
       o.object_type,
       ss.value AS buffer_busy_waits
FROM   v$segment_statistics ss
JOIN   dba_objects o ON o.object_id = ss.obj#
WHERE  ss.statistic_name = 'buffer busy waits'
AND    ss.value > 0
ORDER BY ss.value DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Buffer busy and hot segments ===
PROMPT

-- End of file
