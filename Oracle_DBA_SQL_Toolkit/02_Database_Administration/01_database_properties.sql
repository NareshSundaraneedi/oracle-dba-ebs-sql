--------------------------------------------------------------------------------
-- File Name       : 01_database_properties.sql
-- Category        : 02_Database_Administration
-- Purpose         : List DATABASE_PROPERTIES including default tablespaces and character set
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DATABASE_PROPERTIES holds durable database-level settings that are not
-- all visible in V$PARAMETER (default permanent/temp tablespace, time zone).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Database properties
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DATABASE_PROPERTIES.
-- 2. Important columns
--    PROPERTY_NAME, PROPERTY_VALUE.
-- 3. How to interpret the output
--    DEFAULT_PERMANENT_TABLESPACE and DEFAULT_TEMP_TABLESPACE apply to new users.
-- 4. What indicates a problem
--    Default permanent tablespace is SYSTEM. DBTIMEZONE unexpected after a clone.
-- 5. Recommended DBA action
--    ALTER DATABASE DEFAULT TABLESPACE <users_ts> during a change window if SYSTEM is the default.
-- 6. Production cautions
--    Safe to query. Changing defaults is a change.
-- 7. Required privileges
--    SELECT on DATABASE_PROPERTIES
--------------------------------------------------------------------------------
SELECT property_name, property_value
FROM   database_properties
ORDER BY property_name;

PROMPT
PROMPT === End of query: Database properties ===
PROMPT

-- End of file
