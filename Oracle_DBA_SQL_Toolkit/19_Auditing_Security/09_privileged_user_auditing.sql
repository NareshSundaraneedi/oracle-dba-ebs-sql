--------------------------------------------------------------------------------
-- File Name       : 09_privileged_user_auditing.sql
-- Category        : 19_Auditing_Security
-- Purpose         : SYS/SYSTEM/DBA activity
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Privileged actions. audit_sys_operations writes SYS to the OS audit if traditional; unified policies may capture SYSDBA.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Privileged users last 7 days
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filter high-privilege usernames.
-- 2. Important columns
--    DBUSERNAME, ACTION, OBJECT, TIMESTAMP.
-- 3. How to interpret the output
--    Expected patch-window SYS activity vs unexpected mid-day DROP.
-- 4. What indicates a problem
--    SYS DROP/TRUNCATE outside a window.
-- 5. Recommended DBA action
--    Incident + forensics. Preserve the trail (do not purge).
-- 6. Production cautions
--    Confidential. Time-bounded.
-- 7. Required privileges
--    AUDIT_VIEWER
--------------------------------------------------------------------------------
SELECT event_timestamp, dbusername, userhost, action_name, object_schema, object_name, sql_text
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
AND dbusername IN ('SYS','SYSTEM','SYSKM','SYSBACKUP','SYSDG')
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Privileged users last 7 days ===
PROMPT

-- End of file
