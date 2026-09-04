--------------------------------------------------------------------------------
-- File Name       : 11_sessions_consuming_cpu.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Sessions with highest recent CPU from V$SESSTAT / ASH
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$SESSTAT CPU used by this session is cumulative since login.
-- For 'who is on CPU right now' prefer ASH (licensed) or V$SESSION
-- in ON CPU / wait_class = Idle exclusion.
--
-- ASH queries require Diagnostics Pack. SESSTAT does not.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: CPU from SESSTAT (cumulative) and on-CPU sessions
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins GV$SESSTAT (CPU used by this session) to sessions; lists sessions not waiting.
-- 2. Important columns
--    SID, CPU_CENTS, LAST_CALL_ET, EVENT.
-- 3. How to interpret the output
--    Cumulative CPU favors long-lived sessions. Pair with LAST_CALL_ET.
-- 4. What indicates a problem
--    A session burning CPU with a bad plan (nested loops + high cardinality).
-- 5. Recommended DBA action
--    Get SQL_ID and plan. Do not kill blindly — it may be a needed payroll job.
-- 6. Production cautions
--    Safe. ASH optional query is commented with license note.
-- 7. Required privileges
--    SELECT on GV_$SESSTAT, GV_$STATNAME, GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       s.sql_id,
       s.event,
       s.last_call_et,
       ROUND(st.value/100,1) AS cpu_seconds
FROM   gv$session s
JOIN   gv$sesstat st ON st.inst_id = s.inst_id AND st.sid = s.sid
JOIN   gv$statname sn ON sn.inst_id = st.inst_id AND sn.statistic# = st.statistic#
WHERE  sn.name = 'CPU used by this session'
AND    s.type = 'USER'
AND    st.value > 0
ORDER BY st.value DESC
FETCH FIRST 30 ROWS ONLY;

-- Currently not waiting (likely on CPU or between waits)
SELECT inst_id, sid, serial#, username, sql_id, event, state, wait_class, last_call_et
FROM   gv$session
WHERE  status = 'ACTIVE'
AND    type = 'USER'
AND    wait_class = 'Idle' OR state = 'WAITED SHORT TIME' OR event = 'ON CPU'
ORDER BY last_call_et DESC;

-- LICENSING: Diagnostics Pack required for GV$ACTIVE_SESSION_HISTORY
-- SELECT inst_id, session_id, sql_id, COUNT(*) samples
-- FROM   gv$active_session_history
-- WHERE  sample_time > SYSDATE - 15/1440
-- AND    session_state = 'ON CPU'
-- GROUP BY inst_id, session_id, sql_id
-- ORDER BY samples DESC FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: CPU from SESSTAT (cumulative) and on-CPU sessions ===
PROMPT

-- End of file
