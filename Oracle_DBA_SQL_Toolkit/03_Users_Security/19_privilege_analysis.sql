--------------------------------------------------------------------------------
-- File Name       : 19_privilege_analysis.sql
-- Category        : 03_Users_Security
-- Purpose         : Show privilege analysis captures (12c+ Privilege Analysis)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Privilege Analysis (Database Vault option / 12c feature) records used
-- vs unused privileges. This script only lists existing captures — it
-- does not start a capture (that is a change and may require the option).
--
-- Privilege Analysis historically required Database Vault. Check your license before enabling captures.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Privilege analysis runs
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_PRIV_CAPTURES if the view exists.
-- 2. Important columns
--    NAME, TYPE, ENABLED, ROLES.
-- 3. How to interpret the output
--    No rows may mean the feature was never used or the view is not present.
-- 4. What indicates a problem
--    A capture left ENABLED in production adding overhead.
-- 5. Recommended DBA action
--    Disable leftover captures after exporting results.
-- 6. Production cautions
--    Safe to query. Enabling captures is a licensed change.
-- 7. Required privileges
--    SELECT on DBA_PRIV_CAPTURES
--
-- Optional component. Script handles missing view via a existence check comment.
--------------------------------------------------------------------------------
-- If ORA-00942, Privilege Analysis views are not installed — skip.
SELECT name, type, enabled, roles
FROM   dba_priv_captures
ORDER BY name;

SELECT capture, username, used_role, used_sys_priv
FROM   dba_used_sysprivs
WHERE  ROWNUM <= 200;

PROMPT
PROMPT === End of query: Privilege analysis runs ===
PROMPT

-- End of file
