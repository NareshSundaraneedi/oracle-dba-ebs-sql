--------------------------------------------------------------------------------
-- File Name       : 09_sessions_by_service.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Session counts by SERVICE_NAME
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- On RAC, services pin workloads (OLTP vs batch). Imbalance or
-- sessions on the wrong service after a failover is a configuration bug.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Counts by service and instance
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates GV$SESSION by SERVICE_NAME, INST_ID.
-- 2. Important columns
--    SERVICE_NAME, INST_ID, SESSIONS.
-- 3. How to interpret the output
--    Compare to planned service cardinality (15_RAC/03).
-- 4. What indicates a problem
--    All batch sessions landing on the OLTP node.
-- 5. Recommended DBA action
--    Fix service configuration / TNS. See 15_RAC.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--
-- RAC where applicable. Useful on single instance too.
--------------------------------------------------------------------------------
SELECT
       service_name,
       inst_id,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions
FROM   gv$session
GROUP BY service_name, inst_id
ORDER BY service_name, inst_id;

PROMPT
PROMPT === End of query: Counts by service and instance ===
PROMPT

-- End of file
