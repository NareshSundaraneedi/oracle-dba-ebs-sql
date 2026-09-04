--------------------------------------------------------------------------------
-- File Name       : 19_db_time.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : DB time, DB CPU, and background time from AWR / V$SYS_TIME_MODEL
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DB time is the core load metric (not host CPU). AAS ≈ DB time
-- in seconds / elapsed wall seconds.
--
-- V$SYS_TIME_MODEL is pack-free. DBA_HIST_SYS_TIME_MODEL is Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Time model now and optional AWR
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$SYS_TIME_MODEL.
-- 2. Important columns
--    STAT_NAME, SECONDS.
-- 3. How to interpret the output
--    DB CPU / DB time < 0.5 means wait-dominated. Near 1.0 means CPU-dominated.
-- 4. What indicates a problem
--    DB time much higher than usual for this hour.
-- 5. Recommended DBA action
--    AAS script 20 + top SQL.
-- 6. Production cautions
--    Safe. Hist query requires pack — included separately.
-- 7. Required privileges
--    SELECT on GV_$SYS_TIME_MODEL
--------------------------------------------------------------------------------
SELECT
       inst_id,
       stat_name,
       ROUND(value/1e6,1) AS seconds
FROM   gv$sys_time_model
WHERE  stat_name IN ('DB time','DB CPU','background elapsed time','background cpu time','sql execute elapsed time','parse time elapsed','hard parse elapsed time')
ORDER BY inst_id, seconds DESC;

PROMPT
PROMPT === End of query: Time model now and optional AWR ===
PROMPT

-- End of file
