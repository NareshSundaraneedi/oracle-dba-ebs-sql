--------------------------------------------------------------------------------
-- File Name       : 11_awr_report_generation.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Generate AWR report (instance or global) — instructions and snapshot IDs
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Lists snapshot IDs so you can run awrrpt.sql / awrgrpt.sql
-- manually. This file does not spool a full HTML report automatically.
--
-- LICENSING: AWR report requires Diagnostics Pack. Generating a report is relatively heavy — do not loop it.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Available snapshots and how to run awrrpt
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_HIST_SNAPSHOT.
-- 2. Important columns
--    SNAP_ID, BEGIN_INTERVAL_TIME, INSTANCE_NUMBER.
-- 3. How to interpret the output
--    Pick begin/end snaps that bracket the incident, not the entire weekend.
-- 4. What indicates a problem
--    No snapshots (AWR disabled or SYSAUX issue).
-- 5. Recommended DBA action
--    If licensed, check STATISTICS_LEVEL and snapshot interval (12). Do not enable AWR if unlicensed.
-- 6. Production cautions
--    Diagnostics Pack. awrrpt I/O on SYSAUX.
-- 7. Required privileges
--    SELECT on DBA_HIST_SNAPSHOT
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
SELECT instance_number, snap_id,
       TO_CHAR(begin_interval_time,'DD-MON-RR HH24:MI') begin_time,
       TO_CHAR(end_interval_time,'DD-MON-RR HH24:MI') end_time,
       snap_level,
       error_count
FROM   dba_hist_snapshot
WHERE  begin_interval_time > SYSDATE - 3
ORDER BY snap_id, instance_number;

PROMPT Run from SQL*Plus as a privileged user:
PROMPT   @$ORACLE_HOME/rdbms/admin/awrrpt.sql
PROMPT RAC global report:
PROMPT   @$ORACLE_HOME/rdbms/admin/awrgrpt.sql
PROMPT SQL-specific:
PROMPT   @$ORACLE_HOME/rdbms/admin/awrsqrpt.sql

PROMPT
PROMPT === End of query: Available snapshots and how to run awrrpt ===
PROMPT

-- End of file
