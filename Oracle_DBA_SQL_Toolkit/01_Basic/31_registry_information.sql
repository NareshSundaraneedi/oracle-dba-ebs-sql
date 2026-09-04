--------------------------------------------------------------------------------
-- File Name       : 31_registry_information.sql
-- Category        : 01_Basic
-- Purpose         : Show datapatch / SQL patch registry history
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DBA_REGISTRY_SQLPATCH (12.1.0.2+) is the source of truth for RU/RUR
-- and one-off SQL patches applied by datapatch.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL patch registry
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lists applied and failed SQL patches with action time.
-- 2. Important columns
--    PATCH_ID, VERSION, STATUS, ACTION, DESCRIPTION, ACTION_TIME.
-- 3. How to interpret the output
--    STATUS SUCCESS is healthy. WITH ERRORS means datapatch did not finish — the binary may be patched but SQL is not.
-- 4. What indicates a problem
--    A recent RU with STATUS WITH ERRORS or APPLY not present after a patch window.
-- 5. Recommended DBA action
--    Review $ORACLE_HOME/cfgtoollogs/sqlpatch. Rerun datapatch. Do not open the app if SQL patch is incomplete.
-- 6. Production cautions
--    Safe. Requires 12.1.0.2+ views (present on 19c).
-- 7. Required privileges
--    SELECT on DBA_REGISTRY_SQLPATCH
--
-- Oracle 19c (DBA_REGISTRY_SQLPATCH).
--------------------------------------------------------------------------------
SELECT
       patch_id,
       patch_uid,
       version,
       status,
       action,
       description,
       action_time,
       source_version,
       source_build_description
FROM   dba_registry_sqlpatch
ORDER BY action_time DESC;

PROMPT
PROMPT === End of query: SQL patch registry ===
PROMPT

-- End of file
