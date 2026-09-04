--------------------------------------------------------------------------------
-- File Name       : 06_transport_lag.sql
-- Category        : 17_DataGuard
-- Purpose         : Transport lag
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- TRANSPORT LAG is redo not yet received. Different from apply lag.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Transport lag
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATAGUARD_STATS transport lag.
-- 2. Important columns
--    VALUE.
-- 3. How to interpret the output
--    Transport lag high + apply lag similar = network/LNS. Apply >> transport = apply issue.
-- 4. What indicates a problem
--    Transport lag growing.
-- 5. Recommended DBA action
--    TNS, bandwidth, SYNC vs ASYNC, primary dest errors.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$DATAGUARD_STATS
--------------------------------------------------------------------------------
SELECT name, value, unit, time_computed FROM v$dataguard_stats
WHERE name IN ('transport lag','redo transport lag');

PROMPT
PROMPT === End of query: Transport lag ===
PROMPT

-- End of file
