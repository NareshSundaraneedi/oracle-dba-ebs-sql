--------------------------------------------------------------------------------
-- File Name       : 09_database_role.sql
-- Category        : 01_Basic
-- Purpose         : Show primary / standby / snapshot standby role
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DATABASE_ROLE tells you whether this database is PRIMARY, PHYSICAL STANDBY,
-- LOGICAL STANDBY, or SNAPSHOT STANDBY. Never run DML or application
-- cutover checks until role is confirmed.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database role and open mode
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DATABASE_ROLE, OPEN_MODE, PROTECTION_MODE from V$DATABASE.
-- 2. Important columns
--    DATABASE_ROLE, OPEN_MODE, PROTECTION_MODE, SWITCHOVER_STATUS, DATAGUARD_BROKER.
-- 3. How to interpret the output
--    PRIMARY + READ WRITE is a normal production primary. PHYSICAL STANDBY is usually MOUNTED or OPEN READ ONLY (Active Data Guard).
-- 4. What indicates a problem
--    Role is SNAPSHOT STANDBY when you expected a physical standby (convert back before switchover). SWITCHOVER_STATUS not TO STANDBY when a switchover is planned.
-- 5. Recommended DBA action
--    If role is unexpected, stop and verify broker / DG configuration. Do not open a standby READ WRITE unless converting to snapshot.
-- 6. Production cautions
--    Safe. SWITCHOVER_STATUS of SESSIONS ACTIVE means you must disconnect users before switchover.
-- 7. Required privileges
--    SELECT on V_$DATABASE
--
-- Data Guard optional. Meaningful on any database that may be a DG member.
--------------------------------------------------------------------------------
SELECT
       name,
       db_unique_name,
       database_role,
       open_mode,
       protection_mode,
       protection_level,
       switchover_status,
       dataguard_broker,
       force_logging,
       flashback_on
FROM   v$database;

PROMPT
PROMPT === End of query: Database role and open mode ===
PROMPT

-- End of file
