--------------------------------------------------------------------------------
-- File Name       : 06_sessions_by_machine.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Session counts by client machine
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Identifies which app tier, concurrent tier, or PC is connected.
-- Useful when one apps node is misbehaving.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Counts by machine
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates GV$SESSION by MACHINE.
-- 2. Important columns
--    MACHINE, SESSIONS, USERS.
-- 3. How to interpret the output
--    EBS app tiers should have a stable count. A desktop with 50 sessions is unusual.
-- 4. What indicates a problem
--    One machine opening sessions until PROCESSES is exhausted.
-- 5. Recommended DBA action
--    Check that host's connection pool / runaway script.
-- 6. Production cautions
--    Safe. MACHINE can be shortened or show JDBC thin identifiers.
-- 7. Required privileges
--    SELECT on GV_$SESSION
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       machine,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions,
       COUNT(DISTINCT username) AS usernames
FROM   gv$session
WHERE  type = 'USER'
GROUP BY machine
ORDER BY sessions DESC;

PROMPT
PROMPT === End of query: Counts by machine ===
PROMPT

-- End of file
