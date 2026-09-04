--------------------------------------------------------------------------------
-- File Name       : 02_sga_components.sql
-- Category        : 11_Memory
-- Purpose         : SGA breakdown by pool
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$SGAINFO / V$SGASTAT component sizes.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SGA components
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$SGAINFO.
-- 2. Important columns
--    NAME, BYTES, RESIZEABLE.
-- 3. How to interpret the output
--    Buffer cache + shared pool should dominate an OLTP SGA.
-- 4. What indicates a problem
--    Unexpectedly huge Java pool or streams pool on an EBS DB that does not use them.
-- 5. Recommended DBA action
--    Tune the responsible parameter (java_pool_size, streams_pool_size) in a window.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SGAINFO
--------------------------------------------------------------------------------
SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb, resizeable
FROM gv$sgainfo ORDER BY inst_id, bytes DESC;

PROMPT
PROMPT === End of query: SGA components ===
PROMPT

-- End of file
