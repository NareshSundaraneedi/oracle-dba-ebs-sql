--------------------------------------------------------------------------------
-- File Name       : 09_recyclebin.sql
-- Category        : 02_Database_Administration
-- Purpose         : Show recyclebin contents and space they occupy
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Dropped tables remain in the recyclebin and consume space. EBS sites
-- often disable recyclebin. Purging is destructive and is only generated.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Recyclebin usage by owner
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_RECYCLEBIN and the recyclebin parameter.
-- 2. Important columns
--    OWNER, TYPE, SPACE_MB, OBJECT_NAME, ORIGINAL_NAME.
-- 3. How to interpret the output
--    Large recyclebin objects can make a tablespace look full.
-- 4. What indicates a problem
--    Dropped multi-GB tables sitting in recyclebin during a space incident.
-- 5. Recommended DBA action
--    PURGE is destructive. Generate the command, get approval, then run it manually.
-- 6. Production cautions
--    WARNING: PURGE RECYCLEBIN / PURGE DBA_RECYCLEBIN cannot be undone. Generated only.
-- 7. Required privileges
--    SELECT on DBA_RECYCLEBIN, V_$PARAMETER
--------------------------------------------------------------------------------
SELECT name, value FROM v$parameter WHERE name = 'recyclebin';

SELECT
       owner,
       type,
       COUNT(*) AS objects,
       ROUND(SUM(space) * 8 / 1024, 1) AS approx_mb
FROM   dba_recyclebin
GROUP BY owner, type
ORDER BY approx_mb DESC NULLS LAST;

-- WARNING: Review carefully before executing. Generates purge commands only.
SELECT 'PURGE TABLE ' || owner || '."' || object_name || '";' AS purge_cmd
FROM   dba_recyclebin
WHERE  type = 'TABLE'
AND    space > 0
ORDER BY space DESC;

PROMPT
PROMPT === End of query: Recyclebin usage by owner ===
PROMPT

-- End of file
