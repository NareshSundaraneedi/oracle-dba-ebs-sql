--------------------------------------------------------------------------------
-- File Name       : 03_instance_name.sql
-- Category        : 01_Basic
-- Purpose         : Show instance name, number, and thread
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Identifies which instance the session is connected to. Critical on RAC
-- where the same service can land on any node.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Current instance identity
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$INSTANCE for instance name, number, host, and thread.
-- 2. Important columns
--    INSTANCE_NAME, INSTANCE_NUMBER, HOST_NAME, THREAD#, STATUS, DATABASE_STATUS.
-- 3. How to interpret the output
--    INSTANCE_NUMBER maps to GV$ views. THREAD# maps to redo threads.
-- 4. What indicates a problem
--    Connected to a different RAC node than the one showing the symptom (for example, local temp pressure).
-- 5. Recommended DBA action
--    Reconnect with INSTANCE_NAME in the connect string or use GV$ views for cluster-wide checks.
-- 6. Production cautions
--    Safe. On RAC prefer GV$INSTANCE when comparing all nodes.
-- 7. Required privileges
--    SELECT on V_$INSTANCE
--------------------------------------------------------------------------------
SELECT
       instance_name,
       instance_number,
       host_name,
       thread#,
       status,
       database_status,
       archiver,
       logins,
       shutdown_pending
FROM   v$instance;

PROMPT
PROMPT === End of query: Current instance identity ===
PROMPT

-- End of file
