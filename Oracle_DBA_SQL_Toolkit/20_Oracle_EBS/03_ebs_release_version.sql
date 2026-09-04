--------------------------------------------------------------------------------
-- File Name       : 03_ebs_release_version.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : EBS release, RDBMS, and product versions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_PRODUCT_GROUPS / FND_PRODUCT_INSTALLATIONS show the EBS release (12.2.x) and which products are installed at which patch level.
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
-- QUERY 1: Release and product installations
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_PRODUCT_GROUPS and FND_PRODUCT_INSTALLATIONS.
-- 2. Important columns
--    RELEASE_NAME, PRODUCT_VERSION, STATUS, PATCH_LEVEL.
-- 3. How to interpret the output
--    RELEASE_NAME like 12.2.n. STATUS I = installed. PATCH_LEVEL R12.AD.C.Delta.n etc.
-- 4. What indicates a problem
--    RELEASE_NAME not matching the expected RU. Product STATUS N that should be installed.
-- 5. Recommended DBA action
--    Do not update these tables by hand. Use adop / adpatch history.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT release_name, product_group_id, applications_system_name
FROM fnd_product_groups;

SELECT fa.application_short_name, fpi.product_version, fpi.status, fpi.patch_level, fpi.tablespace, fpi.index_tablespace
FROM fnd_product_installations fpi
JOIN fnd_application fa ON fa.application_id = fpi.application_id
WHERE fpi.status = 'I'
ORDER BY fa.application_short_name;

PROMPT
PROMPT === End of query: Release and product installations ===
PROMPT

-- End of file
