--------------------------------------------------------------------------------
-- File Name       : 10_temp_usage_by_session.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : TEMP consumption by session (pointer to 14_TEMP)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Who is using TEMP right now. Same pattern as 14_TEMP/02 — kept here
-- so storage DBAs find it next to tablespace scripts. Prefer 14_TEMP for
-- sort vs hash detail.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Sessions using TEMP
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins GV$TEMPSEG_USAGE to GV$SESSION.
-- 2. Important columns
--    SID, USERNAME, SQL_ID, MB_USED, SEGTYPE.
-- 3. How to interpret the output
--    SEGTYPE SORT vs HASH vs WORK. Multiple rows per session possible.
-- 4. What indicates a problem
--    One session consuming most of TEMP during business hours.
-- 5. Recommended DBA action
--    Identify SQL_ID and tune or reschedule. Kill only as last resort — generate command in 06_Sessions.
-- 6. Production cautions
--    Safe. GV$TEMPSEG_USAGE can miss some 12c+ PGA-only workareas that have not spilled.
-- 7. Required privileges
--    SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       t.inst_id,
       t.sid,
       s.serial#,
       s.username,
       s.program,
       s.module,
       t.sql_id,
       t.segtype,
       ROUND(t.blocks * 8 / 1024, 1) AS mb_used
FROM   gv$tempseg_usage t
JOIN   gv$session s
       ON s.inst_id = t.inst_id AND s.saddr = t.session_addr
ORDER BY t.blocks DESC;

PROMPT
PROMPT === End of query: Sessions using TEMP ===
PROMPT

-- End of file
