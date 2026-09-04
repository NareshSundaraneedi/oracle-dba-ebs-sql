--------------------------------------------------------------------------------
-- File Name       : 02_dbid.sql
-- Category        : 01_Basic
-- Purpose         : Display DBID used by RMAN, AWR, and Data Guard
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- The DBID uniquely identifies a database incarnation for RMAN catalogs,
-- AWR repositories, and some Data Guard operations. Capture it before any
-- restore, duplicate, or catalog resync.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Current DBID and incarnation
--------------------------------------------------------------------------------
-- 1. What the query does
--    Returns DBID from V$DATABASE plus current incarnation from V$DATABASE_INCARNATION.
-- 2. Important columns
--    DBID, RESETLOGS_CHANGE#, RESETLOGS_TIME, INCARNATION#, STATUS.
-- 3. How to interpret the output
--    CURRENT incarnation is the one RMAN will use unless you RESET DATABASE TO INCARNATION.
-- 4. What indicates a problem
--    A recent RESETLOGS without a new full backup breaks recoverability to the previous incarnation.
-- 5. Recommended DBA action
--    Record DBID in the runbook. After RESETLOGS, take a fresh level 0 backup immediately.
-- 6. Production cautions
--    Read-only. Do not confuse DBID with CON_DBID of a PDB.
-- 7. Required privileges
--    SELECT on V_$DATABASE, V_$DATABASE_INCARNATION
--------------------------------------------------------------------------------
SELECT
       d.dbid,
       d.name,
       d.resetlogs_change#,
       d.resetlogs_time,
       i.incarnation#,
       i.status            AS incarnation_status,
       i.resetlogs_id
FROM   v$database d
JOIN   v$database_incarnation i
       ON i.status = 'CURRENT';

PROMPT
PROMPT === End of query: Current DBID and incarnation ===
PROMPT

-- End of file
