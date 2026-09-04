--------------------------------------------------------------------------------
-- File Name       : 07_audit_purge.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Audit trail purge — generate DBMS_AUDIT_MGMT calls only
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- WARNING: Purging audit is a compliance decision. This only generates the API. Set last_archive_timestamp after exporting to SIEM.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Purge guidance
--------------------------------------------------------------------------------
-- 1. What the query does
--    Shows trail properties if available and prints purge examples as comments.
-- 2. Important columns
--    N/A.
-- 3. How to interpret the output
--    Never purge until SIEM/archive has the records (SOX/PCI).
-- 4. What indicates a problem
--    SYSAUX full of audit and no archive timestamp set — purge will refuse or you will violate policy.
-- 5. Recommended DBA action
--    WARNING: DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL is destructive to audit history.
-- 6. Production cautions
--    WARNING: Generated only.
-- 7. Required privileges
--    AUDIT_ADMIN
--------------------------------------------------------------------------------
PROMPT 1) Export / ship to SIEM
PROMPT 2) Set last archive timestamp
PROMPT 3) Clean
/*
BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    last_archive_time => SYSTIMESTAMP - INTERVAL '90' DAY);
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    use_last_arch_timestamp => TRUE);
END;
/
*/
PROMPT Also consider INIT_CLEANUP and CREATE_PURGE_JOB for ongoing housekeeping.

PROMPT
PROMPT === End of query: Purge guidance ===
PROMPT

-- End of file
