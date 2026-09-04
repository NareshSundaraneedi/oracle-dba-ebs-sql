--------------------------------------------------------------------------------
-- File Name       : 10_open_mode.sql
-- Category        : 01_Basic
-- Purpose         : Show database and PDB open mode
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Confirms whether the CDB and each PDB are MOUNTED, READ ONLY, or
-- READ WRITE. EBS R12.2 databases are typically non-CDB or a single PDB.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: CDB/non-CDB and PDB open modes
--------------------------------------------------------------------------------
-- 1. What the query does
--    Shows V$DATABASE.OPEN_MODE and V$PDBS open mode when running in a CDB.
-- 2. Important columns
--    NAME, OPEN_MODE, RESTRICTED, OPEN_TIME.
-- 3. How to interpret the output
--    EBS application connections require READ WRITE. READ ONLY is expected on an Active Data Guard standby.
-- 4. What indicates a problem
--    PDB in MOUNTED or RESTRICTED YES after patching or a failed PDB open.
-- 5. Recommended DBA action
--    ALTER PLUGGABLE DATABASE <pdb> OPEN; investigate alert log if it fails. Restricted mode blocks normal application users.
-- 6. Production cautions
--    Safe. In a non-CDB the PDB query returns no rows — that is expected.
-- 7. Required privileges
--    SELECT on V_$DATABASE, V_$PDBS
--------------------------------------------------------------------------------
SELECT name, open_mode, database_role
FROM   v$database;

-- Returns rows only in a CDB
SELECT
       con_id,
       name,
       open_mode,
       restricted,
       open_time
FROM   v$pdbs
ORDER BY con_id;

PROMPT
PROMPT === End of query: CDB/non-CDB and PDB open modes ===
PROMPT

-- End of file
