--------------------------------------------------------------------------------
-- File Name       : 04_ad_txk_versions.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : AD and TXK codelevels (R12.2 adop prerequisites)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- R12.2 patching requires known AD/TXK codelevels. AD_RELEASES / patch history and FND_PRODUCT_INSTALLATIONS patch_level for AD and TXK.
--
-- Requires EBS R12.2 objects (APPLSYS/APPS). Will fail on a non-EBS database.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AD/TXK patch levels
--------------------------------------------------------------------------------
-- 1. What the query does
--    Product installations for AD and AK/TXK plus applied patches sample.
-- 2. Important columns
--    PATCH_LEVEL, PATCH_NAME.
-- 3. How to interpret the output
--    Compare to MOS for the EBS 12.2 RU you intend to apply.
-- 4. What indicates a problem
--    AD/TXK below the minimum for an upcoming RU.
-- 5. Recommended DBA action
--    Apply the required AD/TXK patches with adop — not SQL.
-- 6. Production cautions
--    Safe. AD_APPLIED_PATCHES can be large — filtered.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT fa.application_short_name, fpi.patch_level, fpi.product_version, fpi.status
FROM fnd_product_installations fpi
JOIN fnd_application fa ON fa.application_id = fpi.application_id
WHERE fa.application_short_name IN ('AD','FND','AU','AK','TXK')
   OR fpi.patch_level LIKE '%TXK%'
   OR fpi.patch_level LIKE '%AD.%';

SELECT patch_name, patch_type, creation_date
FROM ad_applied_patches
WHERE patch_name LIKE '%AD%' OR patch_name LIKE '%TXK%'
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: AD/TXK patch levels ===
PROMPT

-- End of file
