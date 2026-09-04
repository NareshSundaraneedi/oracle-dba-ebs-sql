--------------------------------------------------------------------------------
-- File Name       : 04_instance_load.sql
-- Category        : 15_RAC
-- Purpose         : Load comparison: sessions, DB CPU, AAS-ish
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Compares instances so you can see imbalance.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Per-instance load
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sessions + time model.
-- 2. Important columns
--    SESSIONS, DB_TIME_S, DB_CPU_S.
-- 3. How to interpret the output
--    Large imbalance after a service failover.
-- 4. What indicates a problem
--    One node 4x DB time of the other with equal CPU_COUNT.
-- 5. Recommended DBA action
--    15/14 node imbalance + service distribution.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$SYS_TIME_MODEL
--------------------------------------------------------------------------------
SELECT inst_id, COUNT(*) sessions, SUM(DECODE(status,'ACTIVE',1,0)) active
FROM gv$session GROUP BY inst_id;
SELECT inst_id, stat_name, ROUND(value/1e6,1) seconds
FROM gv$sys_time_model WHERE stat_name IN ('DB time','DB CPU') ORDER BY inst_id;

PROMPT
PROMPT === End of query: Per-instance load ===
PROMPT

-- End of file
