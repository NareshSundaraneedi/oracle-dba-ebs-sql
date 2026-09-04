--------------------------------------------------------------------------------
-- File Name       : 02_ebs_top_modules.sql
-- Category        : 26_EBS_Performance
-- Purpose         : DB time by MODULE (forms and concurrent programs)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- GV$SESSION + optional ASH. Pack-free session view first.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Active sessions by module
--------------------------------------------------------------------------------
-- 1. What the query does
--    ACTIVE APPS sessions grouped by MODULE.
-- 2. Important columns
--    MODULE, ACTIVE, SAMPLE_EVENT.
-- 3. How to interpret the output
--    A module with many ACTIVE sessions is the current hotspot.
-- 4. What indicates a problem
--    One form module with 50 active sessions — missing index or lock.
-- 5. Recommended DBA action
--    06_Sessions and 10_Locks.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT NVL(module,'(none)') module, COUNT(*) active_sessions,
       MIN(event) sample_event
FROM gv$session WHERE username='APPS' AND status='ACTIVE'
GROUP BY module ORDER BY active_sessions DESC;

PROMPT
PROMPT === End of query: Active sessions by module ===
PROMPT

-- End of file
