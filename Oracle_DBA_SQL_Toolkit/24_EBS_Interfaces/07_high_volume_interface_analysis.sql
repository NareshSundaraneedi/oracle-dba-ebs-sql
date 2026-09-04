--------------------------------------------------------------------------------
-- File Name       : 07_high_volume_interface_analysis.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Which interface is largest / growing (segment size)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Space view for interface tables — purge candidates.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Interface segment sizes
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_SEGMENTS for interface table names.
-- 2. Important columns
--    TABLE, GB.
-- 3. How to interpret the output
--    GL_INTERFACE_HISTORY and RA_INTERFACE_* often need purge/archive.
-- 4. What indicates a problem
--    Interface history bigger than transactional tables.
-- 5. Recommended DBA action
--    Standard purge programs. WARNING: no TRUNCATE.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT owner, segment_name, ROUND(bytes/1024/1024/1024,2) gb
FROM dba_segments
WHERE segment_name LIKE '%INTERFACE%'
OR segment_name LIKE '%IFACE%'
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Interface segment sizes ===
PROMPT

-- End of file
