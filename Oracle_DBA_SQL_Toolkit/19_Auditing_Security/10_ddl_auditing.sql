--------------------------------------------------------------------------------
-- File Name       : 10_ddl_auditing.sql
-- Category        : 19_Auditing_Security
-- Purpose         : DDL statements in the unified trail
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- CREATE/ALTER/DROP/TRUNCATE. High volume if you audit all DDL on EBS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Recent DDL
--------------------------------------------------------------------------------
-- 1. What the query does
--    Action names like CREATE%/ALTER%/DROP%/TRUNCATE.
-- 2. Important columns
--    TIMESTAMP, USER, ACTION, OBJECT.
-- 3. How to interpret the output
--    A cluster of DROPs is a threat or a failed clone cleanup.
-- 4. What indicates a problem
--    DROP TABLE on a product schema.
-- 5. Recommended DBA action
--    Restore from backup if confirmed. Revoke privileges.
-- 6. Production cautions
--    SQL_TEXT may be huge — truncated by the view.
-- 7. Required privileges
--    AUDIT_VIEWER
--------------------------------------------------------------------------------
SELECT event_timestamp, dbusername, action_name, object_schema, object_name
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '3' DAY
AND (action_name LIKE 'CREATE%' OR action_name LIKE 'ALTER%' OR action_name LIKE 'DROP%'
     OR action_name IN ('TRUNCATE TABLE','GRANT','REVOKE'))
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Recent DDL ===
PROMPT

-- End of file
