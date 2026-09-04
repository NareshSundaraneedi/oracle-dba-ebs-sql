--------------------------------------------------------------------------------
-- File Name       : 02_audit_policies.sql
-- Category        : 19_Auditing_Security
-- Purpose         : All unified audit policies
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- AUDIT_UNIFIED_POLICIES lists policy definitions (enabled or not).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Policy definitions
--------------------------------------------------------------------------------
-- 1. What the query does
--    AUDIT_UNIFIED_POLICIES.
-- 2. Important columns
--    POLICY_NAME, AUDIT_OPTION, OBJECT_SCHEMA.
-- 3. How to interpret the output
--    ORA_SECURECONFIG and ORA_LOGON_FAILURES are common Oracle-supplied policies.
-- 4. What indicates a problem
--    No policies defined on a 19c DB that claims to be audited.
-- 5. Recommended DBA action
--    CREATE AUDIT POLICY is a change — not executed.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on AUDIT_UNIFIED_POLICIES
--------------------------------------------------------------------------------
SELECT policy_name, audit_option, audit_option_type, object_schema, object_name, object_type
FROM audit_unified_policies
ORDER BY policy_name, audit_option;

PROMPT
PROMPT === End of query: Policy definitions ===
PROMPT

-- End of file
