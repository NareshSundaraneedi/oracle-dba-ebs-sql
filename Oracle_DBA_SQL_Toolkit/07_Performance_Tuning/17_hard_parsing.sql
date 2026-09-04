--------------------------------------------------------------------------------
-- File Name       : 17_hard_parsing.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Hard parse rate from V$SYSSTAT
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Hard parses consume shared pool latches/mutexes and CPU. A sudden
-- jump usually means literal SQL or a shared pool flush.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Parse statistics (instance)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads parse counts from GV$SYSSTAT.
-- 2. Important columns
--    STAT_NAME, VALUE.
-- 3. How to interpret the output
--    Hard parses should be a tiny fraction of total parses. Compare to a baseline; the absolute value since startup is not a rate.
-- 4. What indicates a problem
--    Hard parses growing quickly (take two snapshots 60s apart).
-- 5. Recommended DBA action
--    Find literal SQL (18/20). Check for recent FLUSH SHARED_POOL.
-- 6. Production cautions
--    Safe. Two-snapshot rate is more meaningful than a single sample.
-- 7. Required privileges
--    SELECT on GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT inst_id, name, value
FROM   gv$sysstat
WHERE  name IN (
         'parse count (total)',
         'parse count (hard)',
         'parse count (failures)',
         'parse time cpu',
         'parse time elapsed',
         'session cursor cache hits',
         'session cursor cache count'
       )
ORDER BY inst_id, name;

PROMPT
PROMPT === End of query: Parse statistics (instance) ===
PROMPT

-- End of file
