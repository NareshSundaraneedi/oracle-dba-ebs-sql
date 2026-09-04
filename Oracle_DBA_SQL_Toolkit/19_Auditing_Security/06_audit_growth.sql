--------------------------------------------------------------------------------
-- File Name       : 06_audit_growth.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Audit volume per day (capacity)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Counts records per day. Housekeeping is required — unified audit does not purge itself.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Daily volume
--------------------------------------------------------------------------------
-- 1. What the query does
--    Group by trunc(event_timestamp).
-- 2. Important columns
--    DAY, RECORDS.
-- 3. How to interpret the output
--    A new policy can 10x volume overnight (DML audit on FND_USER).
-- 4. What indicates a problem
--    Millions of rows/day — SYSAUX risk.
-- 5. Recommended DBA action
--    Narrow policies. Schedule 07 purge. Partitioning of the trail is 19c+ option via DBMS_AUDIT_MGMT.
-- 6. Production cautions
--    Query itself can be expensive — last 7 days only.
-- 7. Required privileges
--    AUDIT_VIEWER
--------------------------------------------------------------------------------
SELECT TRUNC(event_timestamp) day, COUNT(*) records
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
GROUP BY TRUNC(event_timestamp)
ORDER BY 1;

PROMPT
PROMPT === End of query: Daily volume ===
PROMPT

-- End of file
