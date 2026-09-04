--------------------------------------------------------------------------------
-- File Name       : 18_awr_top_wait_events.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Top wait events from AWR for a window
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DBA_HIST_SYSTEM_EVENT deltas. Idle events excluded.
--
-- LICENSING: Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AWR wait event deltas
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes time_waited_micro_delta from consecutive snaps via the hist view's total (uses DBA_HIST_SYSTEM_EVENT with snapshot join — time_waited is cumulative; use *_FG or compute from adjacent snaps). Uses TIME_WAITED_MICRO from hist which is cumulative; we subtract via analytic.
-- 2. Important columns
--    EVENT_NAME, WAIT_S, WAITS.
-- 3. How to interpret the output
--    Compare to the same hour last week. New #1 event is the clue.
-- 4. What indicates a problem
--    log file sync or gc buffer busy becoming #1.
-- 5. Recommended DBA action
--    Open the matching 09_Wait_Events script.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on DBA_HIST_SYSTEM_EVENT, DBA_HIST_SNAPSHOT
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
WITH ev AS (
       SELECT
              sn.begin_interval_time,
              e.instance_number,
              e.event_name,
              e.wait_class,
              e.time_waited_micro
              - LAG(e.time_waited_micro) OVER (PARTITION BY e.instance_number, e.event_name ORDER BY e.snap_id) AS wait_us,
              e.total_waits
              - LAG(e.total_waits) OVER (PARTITION BY e.instance_number, e.event_name ORDER BY e.snap_id) AS waits
       FROM   dba_hist_system_event e
       JOIN   dba_hist_snapshot sn
              ON sn.snap_id = e.snap_id AND sn.dbid = e.dbid AND sn.instance_number = e.instance_number
       WHERE  sn.begin_interval_time > SYSDATE - 1
       AND    e.wait_class <> 'Idle'
)
SELECT event_name, wait_class,
       ROUND(SUM(wait_us)/1e6,1) AS wait_s,
       SUM(waits) AS waits
FROM   ev
WHERE  wait_us > 0
GROUP BY event_name, wait_class
ORDER BY wait_s DESC
FETCH FIRST 25 ROWS ONLY;

PROMPT
PROMPT === End of query: AWR wait event deltas ===
PROMPT

-- End of file
