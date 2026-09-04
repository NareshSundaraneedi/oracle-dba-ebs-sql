--------------------------------------------------------------------------------
-- File Name       : 26_ash_by_machine.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : ASH load by client machine
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds which app tier or concurrent node is generating DB time.
--
-- LICENSING: Diagnostics Pack.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AAS by machine
--------------------------------------------------------------------------------
-- 1. What the query does
--    Groups ASH by MACHINE.
-- 2. Important columns
--    MACHINE, SAMPLES, AAS.
-- 3. How to interpret the output
--    One apps node hot after a load-balancer failure is common.
-- 4. What indicates a problem
--    All AAS from one machine that should be 1/N of the farm.
-- 5. Recommended DBA action
--    Check that node's services / concurrent managers.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on GV_$ACTIVE_SESSION_HISTORY
-- EBS relevance  : Useful for EBS
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE minutes = 60

SELECT NVL(machine,'(none)') machine, COUNT(*) samples,
       ROUND(COUNT(*)/(&minutes*60),2) AS aas
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - &minutes/1440
GROUP BY machine
ORDER BY samples DESC;

PROMPT
PROMPT === End of query: AAS by machine ===
PROMPT

-- End of file
