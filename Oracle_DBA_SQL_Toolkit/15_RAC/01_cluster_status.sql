--------------------------------------------------------------------------------
-- File Name       : 01_cluster_status.sql
-- Category        : 15_RAC
-- Purpose         : cluster_database and instance membership
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SQL-side cluster check. OS crsctl is still required for full CRS health.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Cluster parameters and instances
--------------------------------------------------------------------------------
-- 1. What the query does
--    Parameter + GV$INSTANCE.
-- 2. Important columns
--    CLUSTER_DATABASE, INST_ID, STATUS.
-- 3. How to interpret the output
--    One instance down is a cluster incident even if SQL to the surviving node works.
-- 4. What indicates a problem
--    cluster_database TRUE but only one instance OPEN.
-- 5. Recommended DBA action
--    Check CRS/HAS on the down node. Do not start instance from SQL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, GV_$INSTANCE
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter WHERE name LIKE 'cluster%';
SELECT inst_id, instance_name, host_name, status, startup_time FROM gv$instance ORDER BY inst_id;

PROMPT
PROMPT === End of query: Cluster parameters and instances ===
PROMPT

-- End of file
