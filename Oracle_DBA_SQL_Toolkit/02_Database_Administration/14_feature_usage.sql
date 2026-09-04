--------------------------------------------------------------------------------
-- File Name       : 14_feature_usage.sql
-- Category        : 02_Database_Administration
-- Purpose         : Show DBA_FEATURE_USAGE_STATISTICS for licensing awareness
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Lists features Oracle thinks have been used. This is NOT a license
-- audit by itself, but DETECTED_USAGES > 0 on Pack features is a flag
-- to discuss with license management.
--
-- Diagnostics Pack / Tuning Pack: AWR, ASH, ADDM, SQL Tuning Advisor usage appears here.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Feature usage (currently used)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_FEATURE_USAGE_STATISTICS for currently_used = TRUE.
-- 2. Important columns
--    NAME, CURRENTLY_USED, DETECTED_USAGES, LAST_USAGE_DATE.
-- 3. How to interpret the output
--    AWR / SQL Monitoring / Tuning Pack rows with CURRENTLY_USED TRUE mean those packs have been exercised.
-- 4. What indicates a problem
--    Pack features used on Standard Edition or unlicensed EE options.
-- 5. Recommended DBA action
--    Stop unlicensed feature use. This script does not enable or disable anything.
-- 6. Production cautions
--    Safe. Do not treat this as a legal license report.
-- 7. Required privileges
--    SELECT on DBA_FEATURE_USAGE_STATISTICS
--
-- Licensing: this view itself is in the dictionary; some listed features require packs.
--------------------------------------------------------------------------------
SELECT
       name,
       version,
       currently_used,
       detected_usages,
       last_usage_date,
       first_usage_date
FROM   dba_feature_usage_statistics
WHERE  currently_used = 'TRUE'
ORDER BY name;

PROMPT
PROMPT === End of query: Feature usage (currently used) ===
PROMPT

-- End of file
