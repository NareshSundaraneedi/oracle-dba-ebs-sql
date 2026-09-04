--------------------------------------------------------------------------------
-- File Name       : 13_service_distribution.sql
-- Category        : 15_RAC
-- Purpose         : Sessions per service per instance
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Validates that batch vs OLTP services are isolated.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Service x instance
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SESSION group by service_name, inst_id.
-- 2. Important columns
--    SERVICE, INST, SESSIONS.
-- 3. How to interpret the output
--    A failover may pile both services on one node.
-- 4. What indicates a problem
--    Batch service on the OLTP node during peak.
-- 5. Recommended DBA action
--    Relocate service (srvctl). SQL cannot relocate.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT service_name, inst_id, COUNT(*) sessions
FROM gv$session GROUP BY service_name, inst_id
ORDER BY service_name, inst_id;

PROMPT
PROMPT === End of query: Service x instance ===
PROMPT

-- End of file
