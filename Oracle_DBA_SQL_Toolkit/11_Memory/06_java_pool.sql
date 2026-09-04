--------------------------------------------------------------------------------
-- File Name       : 06_java_pool.sql
-- Category        : 11_Memory
-- Purpose         : Java pool size — usually small on EBS DB tier
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- EBS Java runs on the app tier. A large java_pool_size in the DB is often leftover.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Java pool
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$SGASTAT java pool.
-- 2. Important columns
--    MB.
-- 3. How to interpret the output
--    Few MB unused is fine.
-- 4. What indicates a problem
--    Multi-GB java pool wasting SGA on a DB that does not run Java stored procs.
-- 5. Recommended DBA action
--    Reduce in a window if confirmed unused.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SGASTAT, V_$PARAMETER
--------------------------------------------------------------------------------
SELECT name, display_value FROM v$parameter WHERE name LIKE 'java_pool%';
SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb FROM gv$sgastat WHERE pool = 'java pool';

PROMPT
PROMPT === End of query: Java pool ===
PROMPT

-- End of file
