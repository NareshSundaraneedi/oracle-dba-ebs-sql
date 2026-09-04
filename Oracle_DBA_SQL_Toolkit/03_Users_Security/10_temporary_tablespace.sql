--------------------------------------------------------------------------------
-- File Name       : 10_temporary_tablespace.sql
-- Category        : 03_Users_Security
-- Purpose         : Show temporary tablespace assigned to each user
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Wrong TEMP assignment (for example SYSTEM) causes temp contention
-- and ORA-01652 in unexpected files.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Temporary tablespace per user
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_USERS.TEMPORARY_TABLESPACE.
-- 2. Important columns
--    USERNAME, TEMPORARY_TABLESPACE.
-- 3. How to interpret the output
--    Most users should share the default TEMP. Power users sometimes get a dedicated TEMP.
-- 4. What indicates a problem
--    TEMPORARY_TABLESPACE = SYSTEM or a tablespace that is not TEMPORARY contents.
-- 5. Recommended DBA action
--    ALTER USER x TEMPORARY TABLESPACE TEMP — generated only.
-- 6. Production cautions
--    WARNING: ALTER USER generated only.
-- 7. Required privileges
--    SELECT on DBA_USERS, DBA_TABLESPACES
--------------------------------------------------------------------------------
SELECT
       u.username,
       u.temporary_tablespace,
       t.contents,
       t.status
FROM   dba_users u
LEFT JOIN dba_tablespaces t
       ON t.tablespace_name = u.temporary_tablespace
ORDER BY u.temporary_tablespace, u.username;

PROMPT
PROMPT === End of query: Temporary tablespace per user ===
PROMPT

-- End of file
