--------------------------------------------------------------------------------
-- File Name       : 05_database_version.sql
-- Category        : 01_Basic
-- Purpose         : Show Oracle database version, RU, and compatible setting
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Confirms the software version, Release Update, and COMPATIBLE parameter.
-- Required before applying patches, using new 19c features, or opening a
-- standby created from a different RU.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Banner, version, and compatible
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$VERSION, V$INSTANCE.VERSION, and the COMPATIBLE parameter.
-- 2. Important columns
--    BANNER, VERSION_FULL (19c+), COMPATIBLE, STATUS.
-- 3. How to interpret the output
--    VERSION_FULL includes the RU (for example 19.21.0.0.0). COMPATIBLE controls on-disk compatibility, not the binary version.
-- 4. What indicates a problem
--    COMPATIBLE far below the binary version blocks new features. Mixed RU across RAC nodes is unsupported.
-- 5. Recommended DBA action
--    Align RU across all RAC/DG members. Raise COMPATIBLE only after a full backup and change approval.
-- 6. Production cautions
--    V$VERSION.BANNER_FULL / VERSION_FULL exist in 18c/19c. Older 12.1 databases only have BANNER.
-- 7. Required privileges
--    SELECT on V_$VERSION, V_$INSTANCE, V_$PARAMETER
--
-- Oracle 19c.
--------------------------------------------------------------------------------
SELECT banner FROM v$version;

SELECT version, version_full, status
FROM   v$instance;

SELECT name, value
FROM   v$parameter
WHERE  name IN ('compatible','cpu_count','db_name');

PROMPT
PROMPT === End of query: Banner, version, and compatible ===
PROMPT

-- End of file
