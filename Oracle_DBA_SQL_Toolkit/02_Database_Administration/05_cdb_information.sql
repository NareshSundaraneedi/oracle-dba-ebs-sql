--------------------------------------------------------------------------------
-- File Name       : 05_cdb_information.sql
-- Category        : 02_Database_Administration
-- Purpose         : Show CDB vs non-CDB and container context
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Confirms whether you are connected to a CDB$ROOT, a PDB, or a non-CDB.
-- Many diagnostic views must be queried from the correct container.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Container context
--------------------------------------------------------------------------------
-- 1. What the query does
--    Uses V$DATABASE.CDB and SYS_CONTEXT USERENV values.
-- 2. Important columns
--    CDB, CON_ID, CON_NAME, SESSION_USER.
-- 3. How to interpret the output
--    CDB=YES and CON_NAME=CDB$ROOT means you are not seeing PDB-local objects unless using CDB_* views.
-- 4. What indicates a problem
--    Running EBS object queries in CDB$ROOT — they return nothing or SYS objects only.
-- 5. Recommended DBA action
--    ALTER SESSION SET CONTAINER = <pdb>; or connect to the PDB service.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$DATABASE
--------------------------------------------------------------------------------
SELECT
       d.name,
       d.cdb,
       SYS_CONTEXT('USERENV','CON_ID')   AS con_id,
       SYS_CONTEXT('USERENV','CON_NAME') AS con_name,
       SYS_CONTEXT('USERENV','SESSION_USER') AS session_user,
       SYS_CONTEXT('USERENV','CDB_NAME') AS cdb_name
FROM   v$database d;

PROMPT
PROMPT === End of query: Container context ===
PROMPT

-- End of file
