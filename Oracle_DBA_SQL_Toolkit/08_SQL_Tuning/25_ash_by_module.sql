--------------------------------------------------------------------------------
-- File Name       : 25_ash_by_module.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : ASH load by MODULE (EBS form / concurrent program)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Ranks modules by ASH samples.
--
-- LICENSING: Diagnostics Pack. Best EBS mapping when FND tables are not handy.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AAS by module
--------------------------------------------------------------------------------
-- 1. What the query does
--    Groups ASH by MODULE.
-- 2. Important columns
--    MODULE, SAMPLES, SQL_ID.
-- 3. How to interpret the output
--    EBS concurrent programs set MODULE to the program name.
-- 4. What indicates a problem
--    One program owns AAS during the slowness.
-- 5. Recommended DBA action
--    Folder 26 EBS performance / 25 troubleshooting.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on GV_$ACTIVE_SESSION_HISTORY
-- EBS relevance  : Critical for EBS
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE minutes = 60

SELECT NVL(module,'(none)') module, COUNT(*) samples,
       ROUND(COUNT(*)/(&minutes*60),2) AS aas
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - &minutes/1440
GROUP BY module
ORDER BY samples DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: AAS by module ===
PROMPT

-- End of file
