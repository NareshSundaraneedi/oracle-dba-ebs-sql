--------------------------------------------------------------------------------
-- File Name       : 13_data_access_auditing.sql
-- Category        : 19_Auditing_Security
-- Purpose         : SELECT audit / FGA-style access on sensitive objects
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Unified policies can audit SELECT on specific tables. Traditional FGA is DBA_FGA_AUDIT_TRAIL (EE). Both shown.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Access audit and FGA trail
--------------------------------------------------------------------------------
-- 1. What the query does
--    SELECT actions on a bind object + FGA trail if present.
-- 2. Important columns
--    DBUSERNAME, OBJECT, TIMESTAMP.
-- 3. How to interpret the output
--    Use for 'who read this table' investigations when a policy exists.
-- 4. What indicates a problem
--    Access from an unexpected program to a PII table.
-- 5. Recommended DBA action
--    Revoke and incident process. Do not enable SELECT audit on all APPS tables.
-- 6. Production cautions
--    Define object_p. FGA view may be empty.
-- 7. Required privileges
--    AUDIT_VIEWER
--------------------------------------------------------------------------------
DEFINE object_p = FND_USER

SELECT event_timestamp, dbusername, userhost, action_name, object_schema, object_name
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
AND object_name = '&object_p'
AND action_name IN ('SELECT','UPDATE','DELETE')
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;

SELECT timestamp, db_user, object_schema, object_name, sql_text
FROM dba_fga_audit_trail
WHERE timestamp > SYSDATE-7
AND object_name = '&object_p'
FETCH FIRST 100 ROWS ONLY;

PROMPT
PROMPT === End of query: Access audit and FGA trail ===
PROMPT

-- End of file
