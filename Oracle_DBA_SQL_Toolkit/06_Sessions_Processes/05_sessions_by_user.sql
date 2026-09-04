--------------------------------------------------------------------------------
-- File Name       : 05_sessions_by_user.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Session counts grouped by database username
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Finds which schema is opening too many connections (APPS, a batch
-- user, a misconfigured datasource).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Counts by username and status
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates GV$SESSION by USERNAME, STATUS.
-- 2. Important columns
--    USERNAME, STATUS, SESSIONS.
-- 3. How to interpret the output
--    EBS: APPS will dominate. A sudden spike vs baseline is the signal.
-- 4. What indicates a problem
--    A custom user with hundreds of sessions (connection leak).
-- 5. Recommended DBA action
--    Check the middle-tier pool. Do not raise SESSIONS until the leak is understood.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       NVL(username, 'BACKGROUND') AS username,
       status,
       COUNT(*) AS sessions,
       COUNT(DISTINCT inst_id) AS instances
FROM   gv$session
GROUP BY username, status
ORDER BY sessions DESC;

PROMPT
PROMPT === End of query: Counts by username and status ===
PROMPT

-- End of file
