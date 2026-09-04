--------------------------------------------------------------------------------
-- File Name       : 06_alert_log_location.sql
-- Category        : 02_Database_Administration
-- Purpose         : Locate the ADR alert log XML and text files
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- In 11g+ the alert log lives under DIAGNOSTIC_DEST. This script prints
-- the exact paths so you can tail the correct file on the correct RAC node.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ADR home and alert log path
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$DIAG_INFO for Diag Trace and Diag Alert.
-- 2. Important columns
--    INST_ID, NAME, VALUE.
-- 3. How to interpret the output
--    Diag Trace contains alert_<sid>.log. Diag Alert contains log.xml.
-- 4. What indicates a problem
--    Tailing an old ORACLE_HOME/rdbms/log/alert file that is no longer written.
-- 5. Recommended DBA action
--    Use the Diag Trace path. On RAC, repeat on each node (paths differ by hostname).
-- 6. Production cautions
--    Safe. Reading the alert log is OS-level after you have the path.
-- 7. Required privileges
--    SELECT on GV_$DIAG_INFO
--------------------------------------------------------------------------------
SELECT inst_id, name, value
FROM   gv$diag_info
WHERE  name IN ('ADR Base','ADR Home','Diag Trace','Diag Alert','Default Trace File','Active Problem Count','Active Incident Count')
ORDER BY inst_id, name;

PROMPT
PROMPT === End of query: ADR home and alert log path ===
PROMPT

-- End of file
