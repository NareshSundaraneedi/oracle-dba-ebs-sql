--------------------------------------------------------------------------------
-- File Name       : 04_cpu_vs_wait.sql
-- Category        : 09_Wait_Events
-- Purpose         : CPU vs wait breakdown from the time model
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Answers: is the instance CPU-bound or wait-bound?
-- Meaning: DB CPU is Oracle CPU. DB time - DB CPU ≈ wait (+ unaccounted).
-- Cause: CPU-bound = plans/host saturation. Wait-bound = I/O, locks, commit, cluster.
-- Investigate: this script + AAS. Fix: tune the dominant component, do not add CPU to a lock problem.
--
-- Pack-free (V$SYS_TIME_MODEL).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: DB CPU vs DB time
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes CPU fraction of DB time.
-- 2. Important columns
--    DB_TIME_S, DB_CPU_S, CPU_PCT, WAIT_PCT.
-- 3. How to interpret the output
--    CPU_PCT > 80% CPU-bound. < 40% wait-bound.
-- 4. What indicates a problem
--    CPU_PCT high and OS run queue > CPU_COUNT.
-- 5. Recommended DBA action
--    Top SQL by CPU. If wait-bound, 03_top_wait_events.
-- 6. Production cautions
--    Safe. Since startup.
-- 7. Required privileges
--    SELECT on GV_$SYS_TIME_MODEL
--------------------------------------------------------------------------------
SELECT
       inst_id,
       ROUND(db_time/1e6,1) AS db_time_s,
       ROUND(db_cpu/1e6,1) AS db_cpu_s,
       ROUND(db_cpu*100/NULLIF(db_time,0),1) AS cpu_pct_of_dbtime,
       ROUND((db_time-db_cpu)*100/NULLIF(db_time,0),1) AS wait_or_other_pct
FROM   (
       SELECT inst_id,
              MAX(CASE WHEN stat_name='DB time' THEN value END) db_time,
              MAX(CASE WHEN stat_name='DB CPU' THEN value END) db_cpu
       FROM   gv$sys_time_model
       GROUP BY inst_id
);

PROMPT
PROMPT === End of query: DB CPU vs DB time ===
PROMPT

-- End of file
