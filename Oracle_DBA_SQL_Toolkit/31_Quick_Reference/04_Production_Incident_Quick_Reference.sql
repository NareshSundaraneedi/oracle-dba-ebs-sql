--------------------------------------------------------------------------------
-- File Name       : 04_Production_Incident_Quick_Reference.sql
-- Category        : 31_Quick_Reference
-- Purpose         : Production incident command board (what to collect, what not to do)
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Collect: time started, who is affected, error codes, this spool, alert log excerpt, request_id.
-- Do NOT: bounce, flush shared pool, gather schema stats, kill sessions, delete interface rows, reset APPS password with ALTER USER.
--
-- Confirm DB_UNIQUE_NAME matches the incident ticket before any generated command.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Incident board
--------------------------------------------------------------------------------
-- 1. What the query does
--    Identity, errors in dest/FRA, blockers, resource limits, ICM, plus generate (not run) kill template.
-- 2. Important columns
--    Multiple.
-- 3. How to interpret the output
--    Fill the ticket with these result sets before any change.
-- 4. What indicates a problem
--    Any CRITICAL identity mismatch (wrong DB_UNIQUE_NAME).
-- 5. Recommended DBA action
--    Confirm environment first. Then branch to 30_Advanced matching the error.
-- 6. Production cautions
--    WARNING: kill command is generated with 1=0 safety predicate.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT name, db_unique_name, database_role, open_mode, log_mode FROM v$database;
SELECT instance_name, host_name, status, startup_time FROM gv$instance;
SELECT dest_id, status, error FROM v$archive_dest WHERE error IS NOT NULL;
SELECT ROUND(space_used*100/NULLIF(space_limit,0),1) fra_pct FROM v$recovery_file_dest;
SELECT resource_name, current_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT COUNT(*) blockers FROM gv$session WHERE blocking_session IS NOT NULL;
-- WARNING: Review carefully. Safety predicate 1=0.
SELECT 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||',@'||inst_id||''' IMMEDIATE;' kill_cmd
FROM gv$session WHERE 1=0;

PROMPT
PROMPT === End of query: Incident board ===
PROMPT

-- End of file
