--------------------------------------------------------------------------------
-- File Name       : 10_deadlock_investigation.sql
-- Category        : 10_Locks_Blocking
-- Purpose         : Investigate ORA-00060 deadlocks after they occur
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Points you at the trace. Optionally searches recent ASH for
-- enqueue waits if licensed.
--
-- Deadlocks are resolved by Oracle (one session rolls back).
-- This script does not 'find a live deadlock' — they last milliseconds.
-- Use the alert log / trace file. See also 30_Advanced/06_ora_00060.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Alert log location and recent enqueue ASH (optional)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Prints Diag Trace path; optional ASH enqueue samples.
-- 2. Important columns
--    VALUE path, ASH samples.
-- 3. How to interpret the output
--    Open the ORA-00060 trace — it contains the two SQLs and objects.
-- 4. What indicates a problem
--    Repeated deadlocks on the same tables = application locking order bug.
-- 5. Recommended DBA action
--    Give the trace to development. Do not increase INITRANS to 'fix' deadlocks.
-- 6. Production cautions
--    ASH portion needs Diagnostics Pack — commented.
-- 7. Required privileges
--    SELECT on V_$DIAG_INFO
--------------------------------------------------------------------------------
SELECT name, value FROM v$diag_info
WHERE  name IN ('Diag Trace','Default Trace File','ADR Home');

PROMPT Search the alert log for ORA-00060 and open the referenced trace file.
PROMPT The trace lists Deadlock graph, rows, and SQL.

-- Diagnostics Pack optional:
-- SELECT sample_time, session_id, sql_id, event, blocking_session
-- FROM   gv$active_session_history
-- WHERE  sample_time > SYSDATE - 1
-- AND    event LIKE 'enq:%'
-- ORDER BY sample_time DESC FETCH FIRST 50 ROWS ONLY;

PROMPT
PROMPT === End of query: Alert log location and recent enqueue ASH (optional) ===
PROMPT

-- End of file
