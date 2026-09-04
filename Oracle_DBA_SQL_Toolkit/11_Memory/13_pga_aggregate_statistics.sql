--------------------------------------------------------------------------------
-- File Name       : 13_pga_aggregate_statistics.sql
-- Category        : 11_Memory
-- Purpose         : PGA advice and workarea histogram
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$PGA_TARGET_ADVICE estimates extra cache hits if PGA grows.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: PGA advice
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$PGA_TARGET_ADVICE and V$PGA_TARGET_ADVICE_HISTOGRAM.
-- 2. Important columns
--    PGA_TARGET_FOR_ESTIMATE, ESTD_OVERALLOC_COUNT, ESTD_EXTRA_BYTES_RW.
-- 3. How to interpret the output
--    If extra bytes read/written drops a lot at 2x target, SQL is spilling.
-- 4. What indicates a problem
--    overalloc estimated at current size.
-- 5. Recommended DBA action
--    Raise PGA or fix SQL. Confirm OS memory first.
-- 6. Production cautions
--    Safe. Advice is statistical.
-- 7. Required privileges
--    SELECT on V_$PGA_TARGET_ADVICE
--------------------------------------------------------------------------------
SELECT pga_target_for_estimate, pga_target_factor,
       estd_pga_cache_hit_percentage, estd_overalloc_count, estd_extra_bytes_rw
FROM v$pga_target_advice ORDER BY pga_target_for_estimate;

PROMPT
PROMPT === End of query: PGA advice ===
PROMPT

-- End of file
