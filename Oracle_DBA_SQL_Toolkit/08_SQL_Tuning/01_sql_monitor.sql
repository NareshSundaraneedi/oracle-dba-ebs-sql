--------------------------------------------------------------------------------
-- File Name       : 01_sql_monitor.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Real-Time SQL Monitor status for long-running statements
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$SQL_MONITOR shows statements that ran long enough to be
-- monitored (typically >5 seconds or parallel). Best live view of
-- elapsed, CPU, I/O, and degree of parallelism for one execution.
--
-- LICENSING: Real-Time SQL Monitor (V$SQL_MONITOR) requires Tuning Pack when used via OEM/DBMS_SQLTUNE historically; V$SQL_MONITOR access is Tuning Pack. DBMS_SQLTUNE / SQL Tuning Advisor is Tuning Pack. DBA_HIST_* and ASH are Diagnostics Pack. EXPLAIN PLAN and DBMS_XPLAN.DISPLAY_CURSOR (V$SQL_PLAN) are not pack-licensed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Recent monitored executions
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$SQL_MONITOR for the last day of captured executions.
-- 2. Important columns
--    SQL_ID, STATUS, ELAPSED_S, CPU_S, PX_SERVERS, SID.
-- 3. How to interpret the output
--    STATUS EXECUTING is live. DONE (ERROR) failed. Compare ELAPSED to QUEUING.
-- 4. What indicates a problem
--    A statement EXECUTING for hours with BUFFER_GETS climbing and little I/O — CPU/spin or a bad join.
-- 5. Recommended DBA action
--    Note SQL_ID and KEY, then DISPLAY_CURSOR / report_sql_monitor. Tuning Pack.
-- 6. Production cautions
--    Tuning Pack. Query is relatively cheap with a time filter.
-- 7. Required privileges
--    SELECT on GV_$SQL_MONITOR
--
-- Requires Tuning Pack.
--------------------------------------------------------------------------------
SELECT
       inst_id,
       sid,
       session_serial#,
       sql_id,
       sql_exec_id,
       sql_exec_start,
       status,
       username,
       module,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       ROUND(cpu_time/1e6,1) AS cpu_s,
       buffer_gets,
       disk_reads,
       px_servers_allocated
FROM   gv$sql_monitor
WHERE  sql_exec_start > SYSDATE - 1
ORDER BY elapsed_time DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Recent monitored executions ===
PROMPT

-- End of file
