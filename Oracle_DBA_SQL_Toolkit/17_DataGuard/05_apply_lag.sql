--------------------------------------------------------------------------------
-- File Name       : 05_apply_lag.sql
-- Category        : 17_DataGuard
-- Purpose         : Apply lag from V$DATAGUARD_STATS
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- APPLY LAG is how far the standby data is behind.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Apply lag
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATAGUARD_STATS.
-- 2. Important columns
--    NAME, VALUE, TIME_COMPUTED.
-- 3. How to interpret the output
--    Lag of seconds is normal. Minutes+ needs a ticket during OLTP.
-- 4. What indicates a problem
--    Apply lag growing while transport lag is small → apply problem (CPU, I/O, recovery SLAVE).
-- 5. Recommended DBA action
--    Standby alert / MRP trace. Media recovery performance.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$DATAGUARD_STATS
--------------------------------------------------------------------------------
SELECT name, value, unit, time_computed, datum_time
FROM v$dataguard_stats
WHERE name IN ('apply lag','apply finish time','estimated startup time')
ORDER BY name;

PROMPT
PROMPT === End of query: Apply lag ===
PROMPT

-- End of file
