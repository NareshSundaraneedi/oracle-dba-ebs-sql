--------------------------------------------------------------------------------
-- File Name       : 03_buffer_cache.sql
-- Category        : 11_Memory
-- Purpose         : Buffer cache size, advice, and hit ratio caveats
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Hit ratio is a weak KPI. Use advice and wait events. Difference vs 07 SQL buffer gets: this is cache health, not SQL ranking.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Cache size, advice, default pool
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$BUFFER_POOL, V$DB_CACHE_ADVICE, dirty buffers.
-- 2. Important columns
--    SIZE_FOR_ESTIMATE, ESTD_PHYS_READS.
-- 3. How to interpret the output
--    Advice showing little improvement beyond current size means grow-the-cache will not fix I/O.
-- 4. What indicates a problem
--    Cache tiny vs working set and sequential/scattered reads dominate.
-- 5. Recommended DBA action
--    Grow db_cache_size only if advice and I/O evidence agree. Prefer SQL tuning.
-- 6. Production cautions
--    Safe. Hit ratio query included with a warning.
-- 7. Required privileges
--    SELECT on V_$BUFFER_POOL, V_$DB_CACHE_ADVICE, V_$SYSSTAT
--------------------------------------------------------------------------------
SELECT name, block_size, current_size, buffers FROM v$buffer_pool;
SELECT size_for_estimate, size_factor, estd_physical_reads, estd_physical_read_time
FROM v$db_cache_advice WHERE name = 'DEFAULT' ORDER BY size_for_estimate;
SELECT ROUND(1 - (phys.value/NULLIF(dbacc.value,0)),4) AS cache_hit_ratio_weak_kpi
FROM v$sysstat phys, v$sysstat dbacc
WHERE phys.name = 'physical reads cache'
AND dbacc.name = 'session logical reads';

PROMPT
PROMPT === End of query: Cache size, advice, default pool ===
PROMPT

-- End of file
