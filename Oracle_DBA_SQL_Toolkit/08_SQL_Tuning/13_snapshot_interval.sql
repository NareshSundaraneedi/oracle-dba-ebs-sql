--------------------------------------------------------------------------------
-- File Name       : 13_snapshot_interval.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : AWR retention and interval (DBMS_WORKLOAD_REPOSITORY)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Default 60 minutes / 8 days is often too coarse/short for EBS
-- month-end forensics. This only displays current settings.
--
-- LICENSING: Diagnostics Pack. Changing interval/retention is a change.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AWR interval and retention
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_HIST_WR_CONTROL.
-- 2. Important columns
--    SNAP_INTERVAL, RETENTION, TOPNSQL.
-- 3. How to interpret the output
--    SNAP_INTERVAL +000 01:00:00 is hourly. RETENTION +008 is 8 days.
-- 4. What indicates a problem
--    Interval 60 min hiding a 10-minute spike. Retention 8 days and the complaint is 3 weeks old.
-- 5. Recommended DBA action
--    MODIFY_SNAPSHOT_SETTINGS in a change window if licensed. More frequent snaps increase SYSAUX growth.
-- 6. Production cautions
--    Safe to query. MODIFY not executed.
-- 7. Required privileges
--    SELECT on DBA_HIST_WR_CONTROL
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT
       dbid,
       snap_interval,
       retention,
       topnsql
FROM   dba_hist_wr_control;

PROMPT To change (manual, licensed, change window):
PROMPT   EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(interval => 30, retention => 31*24*60);

PROMPT
PROMPT === End of query: AWR interval and retention ===
PROMPT

-- End of file
