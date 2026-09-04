--------------------------------------------------------------------------------
-- File Name       : 15_ebs_performance_baseline.sql
-- Category        : 26_EBS_Performance
-- Purpose         : Numbers to save each week (EBS baseline)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Spool and keep. Compare next week. Not AWR (pack-free).
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
-- QUERY 1: Baseline snapshot
--------------------------------------------------------------------------------
-- 1. What the query does
--    Counts: sessions, invalids, pending, running, tablespace alert count.
-- 2. Important columns
--    METRIC, VALUE.
-- 3. How to interpret the output
--    Store with a timestamp. Deltas matter more than absolutes.
-- 4. What indicates a problem
--    Pending 10x week-over-week.
-- 5. Recommended DBA action
--    Capacity / purge / managers.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + DBA views
--------------------------------------------------------------------------------
SELECT 'APPS_SESSIONS' m, COUNT(*) v FROM gv$session WHERE username='APPS'
UNION ALL SELECT 'APPS_ACTIVE', SUM(DECODE(status,'ACTIVE',1,0)) FROM gv$session WHERE username='APPS'
UNION ALL SELECT 'INVALIDS', COUNT(*) FROM dba_objects WHERE status='INVALID' AND owner IN ('APPS','APPLSYS')
UNION ALL SELECT 'REQ_RUNNING', COUNT(*) FROM fnd_concurrent_requests WHERE phase_code='R'
UNION ALL SELECT 'REQ_PENDING', COUNT(*) FROM fnd_concurrent_requests WHERE phase_code='P'
UNION ALL SELECT 'REQ_ERROR_24H', COUNT(*) FROM fnd_concurrent_requests
         WHERE phase_code='C' AND status_code='E' AND actual_completion_date>SYSDATE-1;

PROMPT
PROMPT === End of query: Baseline snapshot ===
PROMPT

-- End of file
