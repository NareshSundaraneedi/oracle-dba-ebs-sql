--------------------------------------------------------------------------------
-- File Name       : 12_awr_snapshots.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : AWR snapshot inventory and errors
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Verifies snapshots are being taken. Missing snaps during an
-- outage window means you lost historical evidence.
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
-- QUERY 1: Snapshot coverage
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lists recent snapshots and flush errors.
-- 2. Important columns
--    SNAP_ID, BEGIN_TIME, ERROR_COUNT, FLUSH_ELAPSED.
-- 3. How to interpret the output
--    ERROR_COUNT > 0 or large gaps = SYSAUX pressure or AWR hang.
-- 4. What indicates a problem
--    Gap during the incident.
-- 5. Recommended DBA action
--    Check SYSAUX space and MMON. Do not create a snapshot storm (manual create every minute).
-- 6. Production cautions
--    Pack licensed. CREATE SNAPSHOT is a write — not executed.
-- 7. Required privileges
--    SELECT on DBA_HIST_SNAPSHOT
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT
       instance_number,
       snap_id,
       begin_interval_time,
       end_interval_time,
       flush_elapsed,
       error_count
FROM   dba_hist_snapshot
WHERE  begin_interval_time > SYSDATE - 2
ORDER BY snap_id DESC, instance_number;

PROMPT
PROMPT === End of query: Snapshot coverage ===
PROMPT

-- End of file
