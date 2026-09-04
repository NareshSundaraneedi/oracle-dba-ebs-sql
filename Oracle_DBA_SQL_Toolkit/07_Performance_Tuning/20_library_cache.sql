--------------------------------------------------------------------------------
-- File Name       : 20_library_cache.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Library cache hit ratios and lock/pin counts
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$LIBRARYCACHE namespace health. Low get/pinhitratio plus
-- locks/pins waits indicate parse or invalidation storms.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Library cache namespaces
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$LIBRARYCACHE.
-- 2. Important columns
--    NAMESPACE, GETHITRATIO, PINHITRATIO, RELOADS, INVALIDATIONS.
-- 3. How to interpret the output
--    SQL AREA invalidations/reloads should be low. High RELOADS means objects are aging out or being invalidated.
-- 4. What indicates a problem
--    SQL AREA GETHITRATIO < 0.90 on OLTP or INVALIDATIONS climbing.
-- 5. Recommended DBA action
--    Find invalidation source (DDL, stats with invalidate, grants). See 23.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$LIBRARYCACHE
--------------------------------------------------------------------------------
SELECT
       inst_id,
       namespace,
       gets,
       gethits,
       ROUND(gethitratio,3) AS gethitratio,
       pins,
       pinhits,
       ROUND(pinhitratio,3) AS pinhitratio,
       reloads,
       invalidations
FROM   gv$librarycache
ORDER BY inst_id, namespace;

PROMPT
PROMPT === End of query: Library cache namespaces ===
PROMPT

-- End of file
