--------------------------------------------------------------------------------
-- File Name       : 11_database_status.sql
-- Category        : 01_Basic
-- Purpose         : High-level database health: role, mode, log mode, force logging
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Single-pane check used at the start of every shift or incident.
-- Combines role, open mode, archive mode, and force logging.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database status snapshot
--------------------------------------------------------------------------------
-- 1. What the query does
--    Summarizes V$DATABASE attributes that must be correct for a production EBS or RAC primary.
-- 2. Important columns
--    NAME, DATABASE_ROLE, OPEN_MODE, LOG_MODE, FORCE_LOGGING, FLASHBACK_ON, CONTROLFILE_TYPE.
-- 3. How to interpret the output
--    Production primary: PRIMARY, READ WRITE, ARCHIVELOG, FORCE LOGGING typically YES for Data Guard / GoldenGate.
-- 4. What indicates a problem
--    NOARCHIVELOG on production. FORCE_LOGGING NO when a standby exists. CONTROLFILE_TYPE STANDBY on a database you thought was primary.
-- 5. Recommended DBA action
--    Do not enable ARCHIVELOG or FORCE LOGGING without a change window. Escalate role mismatches immediately.
-- 6. Production cautions
--    Safe. FORCE_LOGGING YES is expected on EBS production with Data Guard.
-- 7. Required privileges
--    SELECT on V_$DATABASE
--------------------------------------------------------------------------------
SELECT
       name,
       dbid,
       db_unique_name,
       database_role,
       open_mode,
       log_mode,
       force_logging,
       flashback_on,
       controlfile_type,
       checkpoint_change#,
       current_scn
FROM   v$database;

PROMPT
PROMPT === End of query: Database status snapshot ===
PROMPT

-- End of file
