--------------------------------------------------------------------------------
-- File Name       : 07_sessions_by_program.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Session counts by PROGRAM
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- PROGRAM distinguishes Forms, JDBC, RMAN, sqlplus, and concurrent
-- managers (FNDLIBR, INVLIBR, etc.).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Counts by program
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates GV$SESSION by PROGRAM.
-- 2. Important columns
--    PROGRAM, SESSIONS.
-- 3. How to interpret the output
--    FNDLIBR is Standard Manager. Many sqlplus sessions may be ad hoc or monitoring.
-- 4. What indicates a problem
--    Unexpected PROGRAM flooding connections (backup agent, Excel ODBC).
-- 5. Recommended DBA action
--    Trace the binary on the client host.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       program,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions
FROM   gv$session
GROUP BY program
ORDER BY sessions DESC;

PROMPT
PROMPT === End of query: Counts by program ===
PROMPT

-- End of file
