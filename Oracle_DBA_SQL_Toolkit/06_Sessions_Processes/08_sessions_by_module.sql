--------------------------------------------------------------------------------
-- File Name       : 08_sessions_by_module.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Session counts by MODULE / ACTION (EBS instrumentation)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- EBS sets MODULE to the form or concurrent program name via
-- DBMS_APPLICATION_INFO. This is the fastest way to map DB load to a
-- screen or concurrent program without joining FND tables.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Counts by module
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates GV$SESSION by MODULE.
-- 2. Important columns
--    MODULE, ACTION, SESSIONS.
-- 3. How to interpret the output
--    Empty MODULE is uninstrumented SQL*Plus or a job that did not set it.
-- 4. What indicates a problem
--    One MODULE with many ACTIVE sessions and a common SQL_ID.
-- 5. Recommended DBA action
--    Tune that program or add a manager specialization.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
-- EBS relevance  : Critical for EBS
--------------------------------------------------------------------------------
SELECT
       NVL(module, '(no module)') AS module,
       NVL(action, '(no action)') AS action,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions
FROM   gv$session
WHERE  type = 'USER'
GROUP BY module, action
ORDER BY sessions DESC;

PROMPT
PROMPT === End of query: Counts by module ===
PROMPT

-- End of file
