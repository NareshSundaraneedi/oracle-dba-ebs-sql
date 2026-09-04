--------------------------------------------------------------------------------
-- File Name       : 01_sga_size.sql
-- Category        : 11_Memory
-- Purpose         : SGA size vs targets and in-memory use
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows SGA_TARGET / MEMORY_TARGET and actual SGA size. Use after a memory change or ORA-04031.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SGA parameters and V$SGA
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads parameters and V$SGA.
-- 2. Important columns
--    SGA_MAX_SIZE, SGA_TARGET, VALUE.
-- 3. How to interpret the output
--    SGA_TARGET 0 with MEMORY_TARGET means AMM. ASMM uses SGA_TARGET > 0.
-- 4. What indicates a problem
--    SGA_TARGET far below SGA_MAX after a failed autotune. Huge unused SGA_MAX reserved from OS.
-- 5. Recommended DBA action
--    Resize only in a window. On RAC resize per instance.
-- 6. Production cautions
--    Safe. Do not ALTER SYSTEM here.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$SGA
--------------------------------------------------------------------------------
SELECT name, display_value FROM v$parameter
WHERE name IN ('memory_target','memory_max_target','sga_target','sga_max_size','lock_sga','use_large_pages');
SELECT name, ROUND(value/1024/1024/1024,2) AS gb FROM v$sga;

PROMPT
PROMPT === End of query: SGA parameters and V$SGA ===
PROMPT

-- End of file
