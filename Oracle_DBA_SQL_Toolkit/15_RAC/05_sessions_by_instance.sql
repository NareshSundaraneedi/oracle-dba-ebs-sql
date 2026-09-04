--------------------------------------------------------------------------------
-- File Name       : 05_sessions_by_instance.sql
-- Category        : 15_RAC
-- Purpose         : User session spread
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Simple count by inst_id for user sessions.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: User sessions per instance
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SESSION type USER.
-- 2. Important columns
--    INST_ID, CNT.
-- 3. How to interpret the output
--    Should roughly match service placement.
-- 4. What indicates a problem
--    All users on inst 1, inst 2 idle.
-- 5. Recommended DBA action
--    SCAN/service/local TNS misconfig.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT inst_id, COUNT(*) user_sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) active
FROM gv$session WHERE type='USER' GROUP BY inst_id ORDER BY inst_id;

PROMPT
PROMPT === End of query: User sessions per instance ===
PROMPT

-- End of file
