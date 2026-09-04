--------------------------------------------------------------------------------
-- File Name       : 13_rac_status.sql
-- Category        : 01_Basic
-- Purpose         : Determine whether the database is RAC and list instances
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Confirms cluster_database parameter and lists all RAC instances.
-- Use GV$ views for subsequent diagnostics when CLUSTER_DATABASE is TRUE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: RAC enabled and instance list
--------------------------------------------------------------------------------
-- 1. What the query does
--    Checks CLUSTER_DATABASE and enumerates GV$INSTANCE.
-- 2. Important columns
--    CLUSTER_DATABASE, INST_ID, INSTANCE_NAME, STATUS, PARALLEL.
-- 3. How to interpret the output
--    CLUSTER_DATABASE TRUE with one instance usually means a second node is down.
-- 4. What indicates a problem
--    An instance in the cluster is not OPEN. PARALLEL NO on a RAC instance is unexpected.
-- 5. Recommended DBA action
--    If a node is down, check crsctl status resource -t (from Grid home) and the cluster alert log. Do not assume SQL can start an instance.
-- 6. Production cautions
--    Safe. crsctl commands are OS-level and are not included here.
-- 7. Required privileges
--    SELECT on GV_$INSTANCE, V_$PARAMETER
--
-- RAC where applicable.
--------------------------------------------------------------------------------
SELECT name, value
FROM   v$parameter
WHERE  name IN ('cluster_database','cluster_database_instances','instance_number');

SELECT
       inst_id,
       instance_name,
       host_name,
       status,
       parallel,
       thread#,
       startup_time
FROM   gv$instance
ORDER BY inst_id;

PROMPT
PROMPT === End of query: RAC enabled and instance list ===
PROMPT

-- End of file
