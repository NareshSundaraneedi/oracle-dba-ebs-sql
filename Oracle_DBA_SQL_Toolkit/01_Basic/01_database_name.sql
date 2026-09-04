--------------------------------------------------------------------------------
-- File Name       : 01_database_name.sql
-- Category        : 01_Basic
-- Purpose         : Identify the current database name and unique name
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Returns the database name (DB_NAME) and unique name (DB_UNIQUE_NAME).
-- Use this first in any incident so you confirm you are connected to the intended
-- primary, standby, or cloned environment before changing anything.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database name and unique name
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$DATABASE for NAME and DB_UNIQUE_NAME and shows the session container.
-- 2. Important columns
--    DB_NAME, DB_UNIQUE_NAME, DBID, CREATED, CON_ID, CON_NAME (if CDB).
-- 3. How to interpret the output
--    DB_NAME is the short database name. DB_UNIQUE_NAME distinguishes Data Guard members and clones that share the same DB_NAME.
-- 4. What indicates a problem
--    DB_UNIQUE_NAME not matching the ticket environment means you are on the wrong database.
-- 5. Recommended DBA action
--    Reconnect using the correct TNS alias / service. Do not proceed with changes until names match the change record.
-- 6. Production cautions
--    Read-only. Safe on production. In a CDB, confirm you are in the intended PDB with SHOW CON_NAME.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE or SELECT on V_$DATABASE
--------------------------------------------------------------------------------
SELECT
       d.name              AS db_name,
       d.db_unique_name    AS db_unique_name,
       d.dbid,
       d.created,
       d.cdb,
       SYS_CONTEXT('USERENV','CON_NAME') AS con_name,
       SYS_CONTEXT('USERENV','CON_ID')   AS con_id
FROM   v$database d;

PROMPT
PROMPT === End of query: Database name and unique name ===
PROMPT

-- End of file
