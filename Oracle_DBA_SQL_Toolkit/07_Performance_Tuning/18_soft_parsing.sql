--------------------------------------------------------------------------------
-- File Name       : 18_soft_parsing.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Soft parse vs execute ratio
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Even soft parses cost. The ideal is parse once, execute many
-- (session cursor cache / bind SQL).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Parse to execute ratio
--------------------------------------------------------------------------------
-- 1. What the query does
--    Computes parse/execute from V$SYSSTAT.
-- 2. Important columns
--    PARSE_TOTAL, EXECUTIONS, PARSE_PER_EXEC.
-- 3. How to interpret the output
--    Parse/exec near 1 means almost no cursor reuse (chatty app or missing binds).
-- 4. What indicates a problem
--    Parse/exec > 0.8 on an OLTP EBS instance.
-- 5. Recommended DBA action
--    Session cursor cache, bind variables, avoid invalidations (23).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SYSSTAT
--------------------------------------------------------------------------------
SELECT
       inst_id,
       MAX(CASE WHEN name = 'parse count (total)' THEN value END) AS parse_total,
       MAX(CASE WHEN name = 'parse count (hard)' THEN value END) AS parse_hard,
       MAX(CASE WHEN name = 'execute count' THEN value END) AS execute_count,
       ROUND(MAX(CASE WHEN name = 'parse count (total)' THEN value END)
             / NULLIF(MAX(CASE WHEN name = 'execute count' THEN value END),0), 3) AS parse_per_exec,
       ROUND(MAX(CASE WHEN name = 'parse count (hard)' THEN value END)
             / NULLIF(MAX(CASE WHEN name = 'parse count (total)' THEN value END),0), 3) AS hard_parse_ratio
FROM   gv$sysstat
WHERE  name IN ('parse count (total)','parse count (hard)','execute count')
GROUP BY inst_id
ORDER BY inst_id;

PROMPT
PROMPT === End of query: Parse to execute ratio ===
PROMPT

-- End of file
