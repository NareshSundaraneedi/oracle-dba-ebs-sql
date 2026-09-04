--------------------------------------------------------------------------------
-- File Name       : 04_shared_pool.sql
-- Category        : 11_Memory
-- Purpose         : Shared pool component detail (memory-focused)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Difference vs 07/21: this file is sizing/advice; 07/21 includes reserved list 4031 symptoms. Both are useful; start here for capacity, 07/21 for incidents.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Shared pool resize and top chunks
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$SGASTAT shared pool + advice.
-- 2. Important columns
--    NAME, MB.
-- 3. How to interpret the output
--    sql area + library cache growth is normal with load. KGLH0 explosion can be child cursor issues.
-- 4. What indicates a problem
--    free memory near 0 AND request_failures (see 07/21).
-- 5. Recommended DBA action
--    Do not flush. See 30 ORA-04031.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SGASTAT, GV_$SHARED_POOL_ADVICE
--------------------------------------------------------------------------------
SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb
FROM gv$sgastat WHERE pool = 'shared pool' AND bytes > 10*1024*1024
ORDER BY inst_id, mb DESC;
SELECT inst_id, shared_pool_size_for_estimate, estd_lc_time_saved
FROM gv$shared_pool_advice ORDER BY 1,2;

PROMPT
PROMPT === End of query: Shared pool resize and top chunks ===
PROMPT

-- End of file
