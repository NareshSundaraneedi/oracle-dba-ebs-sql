--------------------------------------------------------------------------------
-- File Name       : 10_database_links.sql
-- Category        : 02_Database_Administration
-- Purpose         : Inventory database links
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DB links are a security and performance surface. EBS may have links for
-- tax, planning, or custom integrations. Stale links cause distributed
-- transaction hangs.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: DBA database links
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_DB_LINKS. Passwords are never shown.
-- 2. Important columns
--    OWNER, DB_LINK, USERNAME, HOST, CREATED.
-- 3. How to interpret the output
--    HOST is the TNS connect string. USERNAME is the remote authenticated user.
-- 4. What indicates a problem
--    Public links with high-privilege remote users. Links pointing at decommissioned databases.
-- 5. Recommended DBA action
--    Test with a SELECT * FROM dual@link in a controlled session. Drop unused links only with approval.
-- 6. Production cautions
--    Safe to list. Opening a link creates a remote session and may fail if the network is blocked.
-- 7. Required privileges
--    SELECT on DBA_DB_LINKS
--------------------------------------------------------------------------------
SELECT
       owner,
       db_link,
       username,
       host,
       created
FROM   dba_db_links
ORDER BY owner, db_link;

PROMPT
PROMPT === End of query: DBA database links ===
PROMPT

-- End of file
