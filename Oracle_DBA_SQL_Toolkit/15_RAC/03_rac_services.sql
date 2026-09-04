--------------------------------------------------------------------------------
-- File Name       : 03_rac_services.sql
-- Category        : 15_RAC
-- Purpose         : Services, preferred instances, and running where
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ACTIVE_SERVICES / DBA_SERVICES show where work should land.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Services
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SERVICES / V$ACTIVE_SERVICES.
-- 2. Important columns
--    NAME, NETWORK_NAME, GOAL, BLOCKED.
-- 3. How to interpret the output
--    EBS often uses a dedicated batch service.
-- 4. What indicates a problem
--    Service running on the wrong node after failover and not failback.
-- 5. Recommended DBA action
--    srvctl relocate service — OS, not SQL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SERVICES, GV_$ACTIVE_SERVICES
--------------------------------------------------------------------------------
SELECT inst_id, name, network_name, creation_date FROM gv$services ORDER BY name, inst_id;
SELECT inst_id, name, blocked, goal FROM gv$active_services ORDER BY name, inst_id;

PROMPT
PROMPT === End of query: Services ===
PROMPT

-- End of file
