--------------------------------------------------------------------------------
-- File Name       : 16_generate_kill_session.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Generate ALTER SYSTEM KILL SESSION commands (does not execute them)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Produces kill statements for review. KILL SESSION is destructive:
-- open transactions roll back, Forms users lose work, RAC needs
-- @inst_id syntax.
--
-- WARNING: Never run generated KILL commands without identifying the session and obtaining approval.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Generate kill commands for a filtered set
--------------------------------------------------------------------------------
-- 1. What the query does
--    Builds ALTER SYSTEM KILL SESSION 'sid,serial#,@inst' IMMEDIATE.
-- 2. Important columns
--    KILL_CMD, SID, USERNAME, MODULE, LAST_CALL_ET.
-- 3. How to interpret the output
--    Review each row. Adjust the WHERE clause before generating.
-- 4. What indicates a problem
--    N/A — this is a helper, not a health check.
-- 5. Recommended DBA action
--    Copy one command at a time after confirmation.
-- 6. Production cautions
--    WARNING: Destructive. Generated only. IMMEDIATE forces rollback. On RAC include @inst_id.
-- 7. Required privileges
--    SELECT on GV_$SESSION. ALTER SYSTEM is required only to execute the generated command.
--------------------------------------------------------------------------------
-- Example filter: inactive APPS sessions idle > 8 hours. EDIT before use.
SELECT
       'ALTER SYSTEM KILL SESSION ''' || sid || ',' || serial# || ',@' || inst_id || ''' IMMEDIATE;' AS kill_cmd,
       inst_id,
       sid,
       serial#,
       username,
       machine,
       module,
       status,
       last_call_et
FROM   gv$session
WHERE  1 = 0  -- safety: returns no rows until you edit the predicate
-- AND username = 'APPS'
-- AND status = 'INACTIVE'
-- AND last_call_et > 28800
;

PROMPT
PROMPT === End of query: Generate kill commands for a filtered set ===
PROMPT

-- End of file
