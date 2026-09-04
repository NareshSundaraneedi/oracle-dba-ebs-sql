--------------------------------------------------------------------------------
-- File Name       : 04_pdb_information.sql
-- Category        : 02_Database_Administration
-- Purpose         : List pluggable databases, open mode, and recovery status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- For CDB deployments (including some EBS 12.2 on 19c CDB architectures).
-- Non-CDB databases return no V$PDBS rows.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: PDB inventory
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$PDBS and CDB_PDBS.
-- 2. Important columns
--    NAME, OPEN_MODE, RESTRICTED, TOTAL_SIZE, RECOVERY_STATUS.
-- 3. How to interpret the output
--    READ WRITE + RESTRICTED NO is normal for an application PDB.
-- 4. What indicates a problem
--    PDB saved state not OPEN, so it stays MOUNTED after CDB bounce.
-- 5. Recommended DBA action
--    ALTER PLUGGABLE DATABASE <pdb> SAVE STATE after a planned open. Investigate alert log if open fails.
-- 6. Production cautions
--    Safe. Opening/closing PDBs is a change.
-- 7. Required privileges
--    SELECT on V_$PDBS, CDB_PDBS
--
-- CDB only. Harmless no-rows on non-CDB.
--------------------------------------------------------------------------------
SELECT
       con_id,
       name,
       open_mode,
       restricted,
       open_time,
       total_size,
       block_size,
       recovery_status
FROM   v$pdbs
ORDER BY con_id;

SELECT pdb_name, status, creation_time, refresh_mode
FROM   cdb_pdbs
ORDER BY pdb_id;

PROMPT
PROMPT === End of query: PDB inventory ===
PROMPT

-- End of file
