--------------------------------------------------------------------------------
-- File Name       : 11_dml_auditing.sql
-- Category        : 19_Auditing_Security
-- Purpose         : DML audit records (use only if a DML policy exists)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DML audit on transactional EBS tables will flood the trail. This query is for targeted investigations.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Recent DML audit
--------------------------------------------------------------------------------
-- 1. What the query does
--    INSERT/UPDATE/DELETE in the trail.
-- 2. Important columns
--    USER, OBJECT, ACTION, COUNT.
-- 3. How to interpret the output
--    No rows usually means you are not auditing DML (good for volume).
-- 4. What indicates a problem
--    Unexpected DML audit volume after a policy change.
-- 5. Recommended DBA action
--    Disable the overly broad policy (change control) after confirming SIEM coverage.
-- 6. Production cautions
--    Can be enormous — last 12 hours + group by.
-- 7. Required privileges
--    AUDIT_VIEWER
--------------------------------------------------------------------------------
SELECT object_schema, object_name, action_name, dbusername, COUNT(*) cnt
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '12' HOUR
AND action_name IN ('INSERT','UPDATE','DELETE','SELECT')
GROUP BY object_schema, object_name, action_name, dbusername
ORDER BY cnt DESC
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: Recent DML audit ===
PROMPT

-- End of file
