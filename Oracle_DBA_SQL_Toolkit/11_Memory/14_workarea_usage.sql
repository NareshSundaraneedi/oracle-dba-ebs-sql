--------------------------------------------------------------------------------
-- File Name       : 14_workarea_usage.sql
-- Category        : 11_Memory
-- Purpose         : Active SQL workareas (sort/hash in PGA)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$SQL_WORKAREA_ACTIVE shows in-flight sort/hash. spilling = TEMP I/O.
--
-- Complements 14_TEMP. If this view is empty, workareas already finished.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Active workareas
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SQL_WORKAREA_ACTIVE.
-- 2. Important columns
--    SID, OPERATION_TYPE, ACTUAL_MEM_USED, TEMPSEG_SIZE.
-- 3. How to interpret the output
--    TEMPSEG_SIZE > 0 means spill.
-- 4. What indicates a problem
--    Many hash workareas spilling during a concurrent program.
-- 5. Recommended DBA action
--    14_TEMP + SQL tune. Increase PGA only if many one-pass/multi-pass in V$SQL_WORKAREA.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL_WORKAREA_ACTIVE
--------------------------------------------------------------------------------
SELECT inst_id, sid, sql_id, operation_type,
       ROUND(expected_size/1024/1024,1) expected_mb,
       ROUND(actual_mem_used/1024/1024,1) actual_mb,
       ROUND(tempseg_size/1024/1024,1) temp_mb,
       number_passes
FROM gv$sql_workarea_active
ORDER BY actual_mem_used DESC;

PROMPT
PROMPT === End of query: Active workareas ===
PROMPT

-- End of file
