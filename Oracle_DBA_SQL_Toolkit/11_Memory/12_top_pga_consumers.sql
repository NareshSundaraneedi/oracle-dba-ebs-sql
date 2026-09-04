--------------------------------------------------------------------------------
-- File Name       : 12_top_pga_consumers.sql
-- Category        : 11_Memory
-- Purpose         : Top PGA processes including background
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Includes background processes (can matter for PX slaves).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top processes by PGA
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$PROCESS ordered by alloc.
-- 2. Important columns
--    SPID, PROGRAM, PGA_ALLOC_MB.
-- 3. How to interpret the output
--    Many PX slaves each with large PGA multiply quickly.
-- 4. What indicates a problem
--    Sum of top processes ≈ pga_aggregate_limit.
-- 5. Recommended DBA action
--    Reduce parallel degree or workarea.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$PROCESS
--------------------------------------------------------------------------------
SELECT inst_id, spid, program,
       ROUND(pga_used_mem/1024/1024,1) used_mb,
       ROUND(pga_alloc_mem/1024/1024,1) alloc_mb,
       ROUND(pga_max_mem/1024/1024,1) max_mb
FROM gv$process ORDER BY pga_alloc_mem DESC FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: Top processes by PGA ===
PROMPT

-- End of file
