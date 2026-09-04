--------------------------------------------------------------------------------
-- File Name       : 01_all_sessions.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : List all sessions with instance, user, program, and status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Cluster-wide session inventory (GV$SESSION). Use filters in later
-- scripts for active/inactive. This is the baseline 'who is connected'.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: All sessions
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$SESSION excluding idle background noise optionally.
-- 2. Important columns
--    INST_ID, SID, SERIAL#, USERNAME, STATUS, PROGRAM, MACHINE, LOGON_TIME.
-- 3. How to interpret the output
--    BACKGROUND usernames are NULL. USER sessions have USERNAME set.
-- 4. What indicates a problem
--    Session count near the SESSIONS parameter (see 02_Database_Administration/13).
-- 5. Recommended DBA action
--    Identify connection leaks by MACHINE/PROGRAM (scripts 06-08).
-- 6. Production cautions
--    Safe. Output can be large on EBS (Forms + concurrent + SSO).
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       inst_id,
       sid,
       serial#,
       username,
       status,
       type,
       program,
       module,
       action,
       machine,
       service_name,
       logon_time,
       sql_id,
       event,
       last_call_et
FROM   gv$session
ORDER BY inst_id, username, sid;

PROMPT
PROMPT === End of query: All sessions ===
PROMPT

-- End of file
