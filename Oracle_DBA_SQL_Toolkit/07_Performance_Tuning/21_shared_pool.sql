--------------------------------------------------------------------------------
-- File Name       : 21_shared_pool.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Shared pool free memory, advice, and reserved list
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ORA-04031 investigation starting point. Complements 11_Memory/04
-- and 30_Advanced ORA-04031 playbook.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Shared pool memory and reserved area
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$SGASTAT, V$SHARED_POOL_RESERVED, V$SHARED_POOL_ADVICE.
-- 2. Important columns
--    BYTES, REQUEST_FAILURES, LAST_FAILURE_SIZE.
-- 3. How to interpret the output
--    REQUEST_FAILURES > 0 is a 4031 precursor. Advice shows estimated extra hits if you grow the pool — not a mandate.
-- 4. What indicates a problem
--    REQUEST_FAILURES increasing or free memory fragmented (failed requests for small sizes).
-- 5. Recommended DBA action
--    Find large unshared SQL. Do not FLUSH SHARED_POOL during the incident (makes it worse). See 30/08.
-- 6. Production cautions
--    Safe. Shared pool advice is statistical.
-- 7. Required privileges
--    SELECT on GV_$SGASTAT, GV_$SHARED_POOL_RESERVED, GV_$SHARED_POOL_ADVICE
--------------------------------------------------------------------------------
SELECT inst_id, pool, name, ROUND(bytes/1024/1024,1) mb
FROM   gv$sgastat
WHERE  pool = 'shared pool'
AND    (
         name IN ('free memory','sql area','library cache','KGLH0','KGLHD')
         OR bytes > 50*1024*1024
       )
ORDER BY inst_id, bytes DESC;

SELECT inst_id, free_space, avg_free_size, used_space, request_failures, last_failure_size, last_miss_size
FROM   gv$shared_pool_reserved;

SELECT inst_id, shared_pool_size_for_estimate, estd_lc_size, estd_lc_memory_objects, estd_lc_time_saved
FROM   gv$shared_pool_advice
ORDER BY inst_id, shared_pool_size_for_estimate;

PROMPT
PROMPT === End of query: Shared pool memory and reserved area ===
PROMPT

-- End of file
