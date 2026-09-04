--------------------------------------------------------------------------------
-- File Name       : 06_sql_baselines.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : List SQL plan baselines (SPM)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Baselines pin accepted plans. Preferred over profiles for
-- repeatable plan control in 19c.
--
-- SQL Plan Management is Enterprise Edition. Evolving/loading from AWR often used with Diagnostics Pack data.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL plan baselines
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_SQL_PLAN_BASELINES.
-- 2. Important columns
--    SQL_HANDLE, PLAN_NAME, ENABLED, ACCEPTED, REPRODUCED.
-- 3. How to interpret the output
--    ENABLED+ACCEPTED is in force. REPRODUCED NO means the plan could not be reproduced (hint/object change).
-- 4. What indicates a problem
--    A baseline not reproduced — optimizer ignores it and may pick a new expensive plan.
-- 5. Recommended DBA action
--    Investigate object/stats changes. Do not drop baselines during an incident.
-- 6. Production cautions
--    Safe to list. DROP/DISABLE generated only.
-- 7. Required privileges
--    SELECT on DBA_SQL_PLAN_BASELINES
--------------------------------------------------------------------------------
SELECT
       sql_handle,
       plan_name,
       enabled,
       accepted,
       fixed,
       reproduced,
       created,
       last_executed,
       SUBSTR(sql_text,1,160) AS sql_text
FROM   dba_sql_plan_baselines
ORDER BY created DESC;

PROMPT
PROMPT === End of query: SQL plan baselines ===
PROMPT

-- End of file
