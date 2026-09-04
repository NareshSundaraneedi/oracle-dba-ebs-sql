--------------------------------------------------------------------------------
-- File Name       : 21_ash_analysis.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : General ASH breakdown for the last N minutes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Top-level ASH cube: SQL_ID, event, module. Start here, then
-- use the specific ASH scripts.
--
-- LICENSING: Diagnostics Pack. ASH is sampled (1s in memory). Good for 'what is happening now'.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ASH last 15 minutes
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates GV$ACTIVE_SESSION_HISTORY.
-- 2. Important columns
--    SQL_ID, EVENT, MODULE, SAMPLES, PCT.
-- 3. How to interpret the output
--    Samples ≈ seconds of DB time for that key (approx).
-- 4. What indicates a problem
--    One SQL_ID or event owns most samples.
-- 5. Recommended DBA action
--    Drill with 22-26.
-- 6. Production cautions
--    Pack licensed. 15 minute window keeps it cheap.
-- 7. Required privileges
--    SELECT on GV_$ACTIVE_SESSION_HISTORY
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE minutes = 15

SELECT sql_id, NVL(event,'ON CPU') AS event, NVL(module,'-') module,
       COUNT(*) samples,
       ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),1) AS pct
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - &minutes/1440
GROUP BY sql_id, event, module
ORDER BY samples DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: ASH last 15 minutes ===
PROMPT

-- End of file
