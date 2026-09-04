--------------------------------------------------------------------------------
-- File Name       : 07_streams_pool.sql
-- Category        : 11_Memory
-- Purpose         : Streams/GoldenGate pool
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- streams_pool_size is used by Streams and Integrated Extract/Replicat.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Streams pool
--------------------------------------------------------------------------------
-- 1. What the query does
--    Parameter + V$SGASTAT.
-- 2. Important columns
--    MB.
-- 3. How to interpret the output
--    0 if unused. GoldenGate integrated capture needs a sized pool.
-- 4. What indicates a problem
--    OGG errors about streams pool / memory.
-- 5. Recommended DBA action
--    Size per GoldenGate MOS notes — not guessed.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, GV_$SGASTAT
--------------------------------------------------------------------------------
SELECT name, display_value FROM v$parameter WHERE name LIKE 'streams_pool%';
SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb FROM gv$sgastat WHERE pool LIKE '%streams%';

PROMPT
PROMPT === End of query: Streams pool ===
PROMPT

-- End of file
