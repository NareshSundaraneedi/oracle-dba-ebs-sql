--------------------------------------------------------------------------------
-- File Name       : 05_audit_records.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Recent unified audit records (time-bounded)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- UNIFIED_AUDIT_TRAIL is the query view. Always filter by EVENT_TIMESTAMP. Output may contain sensitive SQL.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Last 24 hours sample
--------------------------------------------------------------------------------
-- 1. What the query does
--    Time-bounded UNIFIED_AUDIT_TRAIL.
-- 2. Important columns
--    EVENT_TIMESTAMP, DBUSERNAME, ACTION_NAME, OBJECT_NAME, RETURN_CODE.
-- 3. How to interpret the output
--    RETURN_CODE 0 success. Non-zero is a failure (1017 etc.).
-- 4. What indicates a problem
--    Unexpected DROP/TRUNCATE from a named user.
-- 5. Recommended DBA action
--    Investigate the user/host. Do not disable audit to hide growth.
-- 6. Production cautions
--    Trail can be huge — 24h + FETCH FIRST. Treat as confidential.
-- 7. Required privileges
--    AUDIT_VIEWER or AUDIT_ADMIN
--------------------------------------------------------------------------------
SELECT event_timestamp, dbusername, userhost, action_name, object_schema, object_name,
       return_code, unified_audit_policies
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Last 24 hours sample ===
PROMPT

-- End of file
