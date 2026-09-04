--------------------------------------------------------------------------------
-- File Name       : 20_average_active_sessions.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Average Active Sessions from ASH or estimated from DB time
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- AAS is the best single load number. Compare to CPU_COUNT:
-- AAS on CPU > CPU_COUNT means CPU queued.
--
-- LICENSING: GV$ACTIVE_SESSION_HISTORY is Diagnostics Pack. The V$SYS_TIME_MODEL estimate is pack-free but only a since-startup average.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AAS from ASH last hour (licensed) and CPU_COUNT
--------------------------------------------------------------------------------
-- 1. What the query does
--    Counts ASH samples / samples-per-second.
-- 2. Important columns
--    AAS, ON_CPU, WAITING, CPU_COUNT.
-- 3. How to interpret the output
--    AAS 40 on a 16 CPU host is overloaded. Split by wait_class.
-- 4. What indicates a problem
--    AAS spike matching the user complaint.
-- 5. Recommended DBA action
--    ASH by SQL / event (21-26).
-- 6. Production cautions
--    ASH requires Diagnostics Pack.
-- 7. Required privileges
--    SELECT on GV_$ACTIVE_SESSION_HISTORY, V_$PARAMETER
--
-- Requires Diagnostics Pack for ASH.
--------------------------------------------------------------------------------
SELECT value AS cpu_count FROM v$parameter WHERE name = 'cpu_count';

-- Diagnostics Pack
SELECT
       ROUND(COUNT(*) / 3600, 2) AS aas_last_hour,
       ROUND(SUM(DECODE(session_state,'ON CPU',1,0))/3600,2) AS aas_on_cpu,
       ROUND(SUM(DECODE(session_state,'WAITING',1,0))/3600,2) AS aas_waiting
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - 1/24;

SELECT wait_class, ROUND(COUNT(*)/3600,2) AS aas
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - 1/24
AND    session_state = 'WAITING'
GROUP BY wait_class
ORDER BY aas DESC;

PROMPT
PROMPT === End of query: AAS from ASH last hour (licensed) and CPU_COUNT ===
PROMPT

-- End of file
