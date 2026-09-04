--------------------------------------------------------------------------------
-- File Name       : 17_failed_logins.sql
-- Category        : 03_Users_Security
-- Purpose         : Investigate failed logins from unified audit or DBA_USERS lock state
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Failed logins appear in UNIFIED_AUDIT_TRAIL when unified auditing
-- is enabled (default-on in fresh 19c installs; mixed-mode possible on
-- upgrades). Also infer from LOCKED(TIMED).
--
-- If unified auditing is not enabled, traditional AUD$ / DBA_AUDIT_TRAIL may still be used.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Recent failed logins (unified audit)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Queries UNIFIED_AUDIT_TRAIL for return code 1017 / action LOGON failures.
-- 2. Important columns
--    EVENT_TIMESTAMP, DBUSERNAME, USERHOST, RETURN_CODE, OS_USERNAME.
-- 3. How to interpret the output
--    ORA-1017 storms from one USERHOST often mean a bad password in a config file after a rotation.
-- 4. What indicates a problem
--    Hundreds of failures then LOCKED(TIMED) on APPS.
-- 5. Recommended DBA action
--    Fix the client credential. Unlock with approval. Do not disable the profile lockout.
-- 6. Production cautions
--    UNIFIED_AUDIT_TRAIL can be large — bounded by time. Diagnostics of audit data is licensed as part of the database; Fine Grained Auditing is EE.
-- 7. Required privileges
--    AUDIT_ADMIN or SELECT on UNIFIED_AUDIT_TRAIL / AUDSYS
--
-- Oracle 19c unified auditing. May return no rows if unified audit is not enabled.
--------------------------------------------------------------------------------
SELECT
       username,
       account_status,
       lock_date
FROM   dba_users
WHERE  account_status LIKE 'LOCKED%';

-- Unified audit (19c). Bound the time window.
SELECT
       event_timestamp,
       dbusername,
       userhost,
       os_username,
       terminal,
       return_code,
       unified_audit_policies
FROM   unified_audit_trail
WHERE  event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
AND    (return_code IN (1017, 28000, 28001) OR action_name = 'LOGON')
AND    return_code <> 0
AND    ROWNUM <= 500
ORDER BY event_timestamp DESC;

PROMPT
PROMPT === End of query: Recent failed logins (unified audit) ===
PROMPT

-- End of file
