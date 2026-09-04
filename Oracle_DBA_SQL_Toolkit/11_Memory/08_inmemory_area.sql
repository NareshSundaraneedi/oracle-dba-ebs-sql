--------------------------------------------------------------------------------
-- File Name       : 08_inmemory_area.sql
-- Category        : 11_Memory
-- Purpose         : In-Memory column store area (if licensed/enabled)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- INMEMORY_SIZE > 0 means the IM area is carved from SGA. Requires Database In-Memory option.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: In-Memory parameters and usage
--------------------------------------------------------------------------------
-- 1. What the query does
--    Parameters + V$INMEMORY_AREA if present.
-- 2. Important columns
--    INMEMORY_SIZE, ALLOCATED, USED.
-- 3. How to interpret the output
--    No rows in V$INMEMORY_AREA if IM is off.
-- 4. What indicates a problem
--    IM enabled accidentally consuming SGA from buffer cache.
-- 5. Recommended DBA action
--    Do not enable IM without a license and a plan.
-- 6. Production cautions
--    Safe. View missing if component unused — comment if ORA-00942.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$INMEMORY_AREA
--------------------------------------------------------------------------------
SELECT name, display_value FROM v$parameter WHERE name LIKE 'inmemory%';
-- SELECT pool, ROUND(alloc_bytes/1024/1024,1) alloc_mb, ROUND(used_bytes/1024/1024,1) used_mb
-- FROM v$inmemory_area;

PROMPT
PROMPT === End of query: In-Memory parameters and usage ===
PROMPT

-- End of file
