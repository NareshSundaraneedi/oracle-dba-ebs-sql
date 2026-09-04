--------------------------------------------------------------------------------
-- File Name       : 05_database_connection_issues.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : Database connection issues
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: ORA-12514/12541/12537, timeouts, TNS. Initial: instance logins, listener is OS, service names, processes headroom, restricted mode. Evidence: listener.log, alert log, SCAN (RAC). Causes: listener down, service not registered, restricted, processes full, firewall. Fix: lsnrctl / srvctl (OS). SQL cannot start the listener. Post-fix: new connections succeed from the app tier.
--
-- Production playbook.  lsnrctl / srvctl (OS). SQL cannot start the listener.
-- Post-fix: new connections succeed from the app tier.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database connection issues — queries
--------------------------------------------------------------------------------
-- 1. What the query does
--    Playbook queries for this symptom.
-- 2. Important columns
--    See SELECT list / PROMPT for evidence to collect.
-- 3. How to interpret the output
--    Work Symptom → Initial checks → these SQL → Evidence → Root cause → Fix → Post-fix as in the file header DESCRIPTION.
-- 4. What indicates a problem
--    Matches the symptom in the file name.
-- 5. Recommended DBA action
--    See DESCRIPTION recommended fix. No destructive SQL is auto-run.
-- 6. Production cautions
--    Safe to query. Bounces, kills, and parameter changes are out of band.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT instance_name, status, logins, blocked FROM gv$instance;
SELECT name, network_name FROM v$services;
SELECT resource_name, current_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT value FROM v$parameter WHERE name IN ('local_listener','remote_listener','service_names');

PROMPT
PROMPT === End of query: Database connection issues — queries ===
PROMPT

-- End of file
