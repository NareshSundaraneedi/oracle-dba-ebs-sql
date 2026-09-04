--------------------------------------------------------------------------------
-- File Name       : 05_large_pool.sql
-- Category        : 11_Memory
-- Purpose         : Large pool usage (PX, RMAN, UGA shared server)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Large pool is used by parallel query, RMAN buffers, and shared servers.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Large pool stats
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$SGASTAT pool=large pool.
-- 2. Important columns
--    NAME, MB.
-- 3. How to interpret the output
--    free memory high is OK if PX is idle.
-- 4. What indicates a problem
--    PX running and large pool free memory 0 with PX waits.
-- 5. Recommended DBA action
--    Raise large_pool_size or sga_target and let ASMM move memory.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SGASTAT
--------------------------------------------------------------------------------
SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb
FROM gv$sgastat WHERE pool = 'large pool' ORDER BY inst_id, mb DESC;

PROMPT
PROMPT === End of query: Large pool stats ===
PROMPT

-- End of file
