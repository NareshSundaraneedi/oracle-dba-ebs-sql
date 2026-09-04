--------------------------------------------------------------------------------
-- File Name       : 19_parse_ratio.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Human-readable parse ratios with alert bands
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Wraps 17/18 into alert levels for a health check.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Parse health
--------------------------------------------------------------------------------
-- 1. What the query does
--    Same math as 18 with CASE bands.
-- 2. Important columns
--    HARD_PARSE_RATIO, PARSE_PER_EXEC, ALERT.
-- 3. How to interpret the output
--    Hard parse ratio > 0.20 is WARNING on OLTP; > 0.40 CRITICAL.
-- 4. What indicates a problem
--    CRITICAL after a shared pool flush or login storm of unique SQL.
-- 5. Recommended DBA action
--    See 20/22. Do not increase shared pool blindly.
-- 6. Production cautions
--    Safe. Ratios since startup can hide a recent incident — take a delta.
-- 7. Required privileges
--    SELECT on GV_$SYSSTAT
--------------------------------------------------------------------------------
WITH s AS (
       SELECT inst_id, name, value FROM gv$sysstat
       WHERE  name IN ('parse count (total)','parse count (hard)','execute count')
)
SELECT
       inst_id,
       ROUND(hardp/NULLIF(totp,0),3) AS hard_parse_ratio,
       ROUND(totp/NULLIF(execs,0),3) AS parse_per_exec,
       CASE
         WHEN hardp/NULLIF(totp,0) > 0.40 THEN 'CRITICAL'
         WHEN hardp/NULLIF(totp,0) > 0.20 THEN 'WARNING'
         WHEN hardp/NULLIF(totp,0) > 0.10 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   (
       SELECT inst_id,
              MAX(CASE WHEN name='parse count (hard)' THEN value END) hardp,
              MAX(CASE WHEN name='parse count (total)' THEN value END) totp,
              MAX(CASE WHEN name='execute count' THEN value END) execs
       FROM   s
       GROUP BY inst_id
);

PROMPT
PROMPT === End of query: Parse health ===
PROMPT

-- End of file
