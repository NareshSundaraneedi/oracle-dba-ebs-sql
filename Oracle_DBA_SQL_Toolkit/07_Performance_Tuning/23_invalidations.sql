--------------------------------------------------------------------------------
-- File Name       : 23_invalidations.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Cursor invalidations and recent DDL that may have caused them
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- High invalidations follow statistics jobs, GRANTs, or ALTER TABLE.
-- This script shows library cache invalidations and recent object DDL.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Invalidations and recent DDL
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$LIBRARYCACHE.INVALIDATIONS plus recent LAST_DDL_TIME.
-- 2. Important columns
--    INVALIDATIONS, OWNER, OBJECT_NAME, LAST_DDL_TIME.
-- 3. How to interpret the output
--    A stats job that invalidates (default DBMS_STATS) can flip plans cluster-wide.
-- 4. What indicates a problem
--    Invalidations spike aligned with an auto-stats window.
-- 5. Recommended DBA action
--    Use NO_INVALIDATE carefully (understand the tradeoff). Avoid mid-day DDL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$LIBRARYCACHE, DBA_OBJECTS
--------------------------------------------------------------------------------
SELECT inst_id, namespace, invalidations, reloads
FROM   gv$librarycache
WHERE  invalidations > 0
ORDER BY invalidations DESC;

SELECT owner, object_type, object_name, last_ddl_time
FROM   dba_objects
WHERE  last_ddl_time > SYSDATE - 1
AND    owner NOT IN ('SYS','SYSTEM')
AND    object_type IN ('TABLE','INDEX','PACKAGE','PACKAGE BODY','VIEW','SYNONYM')
ORDER BY last_ddl_time DESC
FETCH FIRST 80 ROWS ONLY;

PROMPT
PROMPT === End of query: Invalidations and recent DDL ===
PROMPT

-- End of file
