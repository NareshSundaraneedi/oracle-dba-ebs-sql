--------------------------------------------------------------------------------
-- File Name       : 04_temp_spills.sql
-- Category        : 14_TEMP
-- Purpose         : Evidence of PGA workarea spills to TEMP
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Combines workarea active + sysstat physical reads direct temporary.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Spills
--------------------------------------------------------------------------------
-- 1. What the query does
--    Workareas with TEMPSEG_SIZE plus sysstat.
-- 2. Important columns
--    TEMP_MB, PASSES.
-- 3. How to interpret the output
--    number_passes > 1 is multi-pass (very expensive).
-- 4. What indicates a problem
--    Multi-pass hash joins during peak.
-- 5. Recommended DBA action
--    Increase PGA or tune the join. 11_Memory/14.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SQL_WORKAREA_ACTIVE, GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT inst_id, sql_id, operation_type, number_passes,
       ROUND(tempseg_size/1024/1024,1) temp_mb
FROM gv$sql_workarea_active WHERE tempseg_size > 0;
SELECT inst_id, name, value FROM gv$sysstat
WHERE name LIKE '%temporary%';

PROMPT
PROMPT === End of query: Spills ===
PROMPT

-- End of file
