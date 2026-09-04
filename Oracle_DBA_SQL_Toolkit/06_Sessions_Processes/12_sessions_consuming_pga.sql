--------------------------------------------------------------------------------
-- File Name       : 12_sessions_consuming_pga.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Top PGA consumers among current sessions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Uses GV$PROCESS.PGA_USED_MEM / PGA_ALLOC_MEM joined to sessions.
-- Complements 11_Memory PGA scripts.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Sessions by PGA
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins GV$SESSION to GV$PROCESS.
-- 2. Important columns
--    SID, PGA_USED_MB, PGA_ALLOC_MB, SQL_ID.
-- 3. How to interpret the output
--    PGA of several GB often means a large hash/sort that should have spilled or a leak (unclosed LOB/cursor).
-- 4. What indicates a problem
--    One session near pga_aggregate_limit (ORA-04036) or triggering ORA-04030.
-- 5. Recommended DBA action
--    Tune SQL workarea or raise pga_aggregate_target only after analysis. See 11_Memory.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$PROCESS
--------------------------------------------------------------------------------
SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       s.sql_id,
       ROUND(p.pga_used_mem/1024/1024,1) AS pga_used_mb,
       ROUND(p.pga_alloc_mem/1024/1024,1) AS pga_alloc_mb,
       ROUND(p.pga_max_mem/1024/1024,1) AS pga_max_mb
FROM   gv$session s
JOIN   gv$process p ON p.inst_id = s.inst_id AND p.addr = s.paddr
WHERE  s.type = 'USER'
ORDER BY p.pga_alloc_mem DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Sessions by PGA ===
PROMPT

-- End of file
