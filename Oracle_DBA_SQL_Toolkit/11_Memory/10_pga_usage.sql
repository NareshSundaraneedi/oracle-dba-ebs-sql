--------------------------------------------------------------------------------
-- File Name       : 10_pga_usage.sql
-- Category        : 11_Memory
-- Purpose         : Current PGA aggregate usage vs target
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$PGASTAT is the instance view of PGA health.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: PGASTAT
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$PGASTAT key rows.
-- 2. Important columns
--    aggregate PGA target, total PGA allocated, over allocation count.
-- 3. How to interpret the output
--    over allocation count > 0 means target was exceeded.
-- 4. What indicates a problem
--    total PGA allocated >> target plus temp spills (14_TEMP).
-- 5. Recommended DBA action
--    Tune SQL workareas or raise target after OS headroom check.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$PGASTAT
--------------------------------------------------------------------------------
SELECT inst_id, name, value FROM gv$pgastat
WHERE name IN (
  'aggregate PGA target parameter','aggregate PGA auto target','total PGA allocated',
  'total PGA inuse','maximum PGA allocated','over allocation count',
  'extra bytes read/written','cache hit percentage','process count')
ORDER BY inst_id, name;

PROMPT
PROMPT === End of query: PGASTAT ===
PROMPT

-- End of file
