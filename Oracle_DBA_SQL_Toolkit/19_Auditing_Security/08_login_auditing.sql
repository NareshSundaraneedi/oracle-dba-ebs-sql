--------------------------------------------------------------------------------
-- File Name       : 08_login_auditing.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Successful and failed logons
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- LOGON actions in unified audit. Difference vs 03_Users/17: this file is the audit-folder home and includes successes for pattern analysis.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Logons last day
--------------------------------------------------------------------------------
-- 1. What the query does
--    ACTION_NAME LOGON.
-- 2. Important columns
--    DBUSERNAME, USERHOST, RETURN_CODE, COUNT.
-- 3. How to interpret the output
--    Failed storms from one host = bad password in a config.
-- 4. What indicates a problem
--    Successes from an unexpected country/host for SYS.
-- 5. Recommended DBA action
--    Fix credentials. Review network ACLs. Do not unlock without identifying the source.
-- 6. Production cautions
--    Time-bounded.
-- 7. Required privileges
--    AUDIT_VIEWER
--------------------------------------------------------------------------------
SELECT dbusername, userhost, return_code, COUNT(*) cnt
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
AND action_name = 'LOGON'
GROUP BY dbusername, userhost, return_code
ORDER BY cnt DESC
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: Logons last day ===
PROMPT

-- End of file
