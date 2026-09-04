--------------------------------------------------------------------------------
-- File Name       : 04_host_name.sql
-- Category        : 01_Basic
-- Purpose         : Identify the database server host for the current instance
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows the host name reported by the Oracle instance. Use it to confirm
-- OS-level work (alert log, OSWatcher, hugepages) is being done on the
-- correct server.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Host name for this instance and all RAC instances
--------------------------------------------------------------------------------
-- 1. What the query does
--    Returns HOST_NAME from V$INSTANCE and GV$INSTANCE.
-- 2. Important columns
--    INST_ID, INSTANCE_NAME, HOST_NAME, STARTUP_TIME.
-- 3. How to interpret the output
--    Each RAC node has its own HOST_NAME. Single-instance databases return one row from GV$.
-- 4. What indicates a problem
--    Alert log or OS metrics collected from a different host than the instance serving the workload.
-- 5. Recommended DBA action
--    Collect diagnostics from the host(s) listed here. For RAC, collect from every node.
-- 6. Production cautions
--    HOST_NAME is the Oracle-reported name and may be a short name, not the FQDN.
-- 7. Required privileges
--    SELECT on GV_$INSTANCE
--------------------------------------------------------------------------------
SELECT
       inst_id,
       instance_name,
       host_name,
       startup_time,
       status
FROM   gv$instance
ORDER BY inst_id;

PROMPT
PROMPT === End of query: Host name for this instance and all RAC instances ===
PROMPT

-- End of file
