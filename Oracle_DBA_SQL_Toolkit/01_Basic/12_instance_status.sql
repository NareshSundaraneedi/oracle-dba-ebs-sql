--------------------------------------------------------------------------------
-- File Name       : 12_instance_status.sql
-- Category        : 01_Basic
-- Purpose         : Show instance status, logins, and archiver health
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$INSTANCE.STATUS should be OPEN for an application database.
-- ARCHIVER FAILED or logins RESTRICTED are production incidents.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Instance status and login mode
--------------------------------------------------------------------------------
-- 1. What the query does
--    Checks STATUS, ARCHIVER, LOGINS, SHUTDOWN_PENDING for all instances.
-- 2. Important columns
--    STATUS (STARTED/MOUNTED/OPEN), ARCHIVER, LOGINS, SHUTDOWN_PENDING, ACTIVE_STATE.
-- 3. How to interpret the output
--    OPEN + ALLOWED is normal. RESTRICTED is used during maintenance. ARCHIVER FAILED means redo cannot be archived.
-- 4. What indicates a problem
--    ARCHIVER FAILED or STOPPED on a primary in ARCHIVELOG. LOGINS RESTRICTED unexpectedly. SHUTDOWN_PENDING YES.
-- 5. Recommended DBA action
--    If archiver failed: free FRA / archive dest, then archive leftover logs. If restricted unexpectedly: ALTER SYSTEM DISABLE RESTRICTED SESSION after verifying why it was set.
-- 6. Production cautions
--    Safe. Do not disable restricted session during a patch window.
-- 7. Required privileges
--    SELECT on GV_$INSTANCE
--------------------------------------------------------------------------------
SELECT
       inst_id,
       instance_name,
       status,
       database_status,
       archiver,
       logins,
       shutdown_pending,
       active_state,
       blocked
FROM   gv$instance
ORDER BY inst_id;

PROMPT
PROMPT === End of query: Instance status and login mode ===
PROMPT

-- End of file
