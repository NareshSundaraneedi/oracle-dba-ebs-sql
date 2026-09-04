--------------------------------------------------------------------------------
-- File Name       : 13_switchover_readiness.sql
-- Category        : 17_DataGuard
-- Purpose         : SWITCHOVER_STATUS and sessions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SWITCHOVER_STATUS must be TO STANDBY on primary (or SESSIONS ACTIVE). Do not switchover if not ready.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Switchover readiness
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATABASE.SWITCHOVER_STATUS + user sessions.
-- 2. Important columns
--    SWITCHOVER_STATUS, USER_SESSIONS.
-- 3. How to interpret the output
--    TO STANDBY = ready. SESSIONS ACTIVE = disconnect users first. NOT ALLOWED = not ready.
-- 4. What indicates a problem
--    NOT ALLOWED — do not attempt switchover.
-- 5. Recommended DBA action
--    Resolve apply/transport. Use broker SWITCHOVER TO <standby> after a change window.
-- 6. Production cautions
--    Safe. No SWITCHOVER command executed.
-- 7. Required privileges
--    SELECT on V_$DATABASE, GV_$SESSION
--------------------------------------------------------------------------------
SELECT db_unique_name, database_role, switchover_status, open_mode FROM v$database;
SELECT COUNT(*) user_sessions FROM gv$session WHERE type='USER';
PROMPT If SESSIONS ACTIVE, disconnect application sessions before switchover.

PROMPT
PROMPT === End of query: Switchover readiness ===
PROMPT

-- End of file
