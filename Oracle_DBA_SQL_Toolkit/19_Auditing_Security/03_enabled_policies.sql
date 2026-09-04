--------------------------------------------------------------------------------
-- File Name       : 03_enabled_policies.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Which unified policies are enabled and on whom
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- AUDIT_UNIFIED_ENABLED_POLICIES is the enforcement list.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Enabled policies
--------------------------------------------------------------------------------
-- 1. What the query does
--    AUDIT_UNIFIED_ENABLED_POLICIES.
-- 2. Important columns
--    POLICY_NAME, ENABLED_OPT, ENTITY_NAME, SUCCESS, FAILURE.
-- 3. How to interpret the output
--    ENABLED_OPT BY USER / EXCEPT USER / ON USER.
-- 4. What indicates a problem
--    ORA_LOGON_FAILURES not enabled — failed logins not captured here.
-- 5. Recommended DBA action
--    AUDIT POLICY ... ENABLE is a change.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on AUDIT_UNIFIED_ENABLED_POLICIES
--------------------------------------------------------------------------------
SELECT policy_name, enabled_opt, entity_name, entity_type, success, failure
FROM audit_unified_enabled_policies
ORDER BY policy_name, entity_name;

PROMPT
PROMPT === End of query: Enabled policies ===
PROMPT

-- End of file
