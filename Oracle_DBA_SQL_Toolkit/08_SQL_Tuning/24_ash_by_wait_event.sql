--------------------------------------------------------------------------------
-- File Name       : 24_ash_by_wait_event.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : ASH filtered to one wait event
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- When system event #1 is known (for example log file sync),
-- this shows which SQL/sessions contributed.
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
-- QUERY 1: ASH for one event
--------------------------------------------------------------------------------
-- 1. What the query does
--    Filters ASH by EVENT.
-- 2. Important columns
--    SQL_ID, MODULE, SAMPLES.
-- 3. How to interpret the output
--    Maps a wait event back to workload.
-- 4. What indicates a problem
--    All log file sync samples from one chatty module.
-- 5. Recommended DBA action
--    Fix that module's commit rate.
-- 6. Production cautions
--    Pack licensed.
-- 7. Required privileges
--    SELECT on GV_$ACTIVE_SESSION_HISTORY
--
-- Requires Diagnostics Pack.
--------------------------------------------------------------------------------
DEFINE event_p = log file sync
DEFINE minutes = 60

SELECT sql_id, module, program, COUNT(*) samples
FROM   gv$active_session_history
WHERE  event = '&event_p'
AND    sample_time > SYSDATE - &minutes/1440
GROUP BY sql_id, module, program
ORDER BY samples DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: ASH for one event ===
PROMPT

-- End of file
