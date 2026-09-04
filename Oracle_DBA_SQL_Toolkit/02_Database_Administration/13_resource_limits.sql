--------------------------------------------------------------------------------
-- File Name       : 13_resource_limits.sql
-- Category        : 02_Database_Administration
-- Purpose         : Compare processes/sessions usage against initialization limits
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ORA-00018 / ORA-00020 occur when sessions or processes hit the
-- initialization parameter. Check this during connection storms.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Processes and sessions utilization
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins V$RESOURCE_LIMIT with current counts.
-- 2. Important columns
--    RESOURCE_NAME, CURRENT_UTILIZATION, MAX_UTILIZATION, LIMIT_VALUE.
-- 3. How to interpret the output
--    CURRENT close to LIMIT is an imminent outage. MAX_UTILIZATION shows the high-water mark since startup.
-- 4. What indicates a problem
--    CURRENT_UTILIZATION / LIMIT > 85% for processes or sessions.
-- 5. Recommended DBA action
--    Increase processes (and sessions, which defaults to processes*1.5) in a bounce window, or find the connection leak.
-- 6. Production cautions
--    Safe. Raising processes needs more process memory and a bounce if not dynamic enough on your version — on 19c processes is not dynamic.
-- 7. Required privileges
--    SELECT on V_$RESOURCE_LIMIT, V_$PARAMETER
--------------------------------------------------------------------------------
SELECT
       resource_name,
       current_utilization,
       max_utilization,
       initial_allocation,
       limit_value,
       CASE
         WHEN REGEXP_LIKE(limit_value, '^[0-9]+$')
          AND current_utilization * 100 / TO_NUMBER(limit_value) > 95 THEN 'CRITICAL'
         WHEN REGEXP_LIKE(limit_value, '^[0-9]+$')
          AND current_utilization * 100 / TO_NUMBER(limit_value) > 85 THEN 'WARNING'
         WHEN REGEXP_LIKE(limit_value, '^[0-9]+$')
          AND current_utilization * 100 / TO_NUMBER(limit_value) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   v$resource_limit
WHERE  resource_name IN ('processes','sessions','transactions','enqueue_locks','dml_locks','max_shared_servers')
ORDER BY resource_name;

PROMPT
PROMPT === End of query: Processes and sessions utilization ===
PROMPT

-- End of file
