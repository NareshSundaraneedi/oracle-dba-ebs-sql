--------------------------------------------------------------------------------
-- File Name       : 12_failed_login_auditing.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Failed logins only (1017/28000)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 08: failures only, plus LOCKED accounts correlation.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Failed logins
--------------------------------------------------------------------------------
-- 1. What the query does
--    RETURN_CODE in (1017,28000,28001).
-- 2. Important columns
--    USERHOST, DBUSERNAME, CNT.
-- 3. How to interpret the output
--    28000 is locked account — often the result of 1017 storms.
-- 4. What indicates a problem
--    APPS 1017 from a concurrent node after a password change.
-- 5. Recommended DBA action
--    Update the config / wallet. Unlock with approval.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    AUDIT_VIEWER / SELECT on DBA_USERS
--------------------------------------------------------------------------------
SELECT dbusername, userhost, return_code, COUNT(*) cnt,
       MIN(event_timestamp) first_seen, MAX(event_timestamp) last_seen
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
AND return_code IN (1017, 28000, 28001)
GROUP BY dbusername, userhost, return_code
ORDER BY cnt DESC;

SELECT username, account_status, lock_date FROM dba_users WHERE account_status LIKE '%LOCK%';

PROMPT
PROMPT === End of query: Failed logins ===
PROMPT

-- End of file
