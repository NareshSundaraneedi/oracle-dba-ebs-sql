--------------------------------------------------------------------------------
-- File Name       : 19_session_process_utilization.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Utilization of processes/sessions parameters with headroom alerts
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Combines V$RESOURCE_LIMIT with current session counts. Use during
-- connection storms and before raising processes.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Utilization vs limits
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$RESOURCE_LIMIT plus per-instance session counts.
-- 2. Important columns
--    CURRENT_UTILIZATION, LIMIT_VALUE, ALERT_LEVEL.
-- 3. How to interpret the output
--    >85% WARNING, >95% CRITICAL.
-- 4. What indicates a problem
--    CURRENT ≈ LIMIT — next connection gets ORA-00020 / ORA-00018.
-- 5. Recommended DBA action
--    Find leaks first (by machine/program). Raising processes requires a bounce on 19c.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$RESOURCE_LIMIT, GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       resource_name,
       current_utilization,
       max_utilization,
       limit_value,
       CASE
         WHEN REGEXP_LIKE(limit_value,'^[0-9]+$')
          AND current_utilization*100/TO_NUMBER(limit_value) > 95 THEN 'CRITICAL'
         WHEN REGEXP_LIKE(limit_value,'^[0-9]+$')
          AND current_utilization*100/TO_NUMBER(limit_value) > 85 THEN 'WARNING'
         WHEN REGEXP_LIKE(limit_value,'^[0-9]+$')
          AND current_utilization*100/TO_NUMBER(limit_value) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   v$resource_limit
WHERE  resource_name IN ('processes','sessions');

SELECT inst_id, COUNT(*) sessions,
       SUM(DECODE(type,'USER',1,0)) user_sessions,
       SUM(DECODE(type,'BACKGROUND',1,0)) bg_sessions
FROM   gv$session
GROUP BY inst_id
ORDER BY inst_id;

PROMPT
PROMPT === End of query: Utilization vs limits ===
PROMPT

-- End of file
