--------------------------------------------------------------------------------
-- File Name       : 10_ebs_wait_events.sql
-- Category        : 26_EBS_Performance
-- Purpose         : Wait events for APPS sessions only
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Filters system noise from SYS backups.
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
-- QUERY 1: APPS waiters
--------------------------------------------------------------------------------
-- 1. What the query does
--    ACTIVE APPS wait_class <> Idle.
-- 2. Important columns
--    EVENT, CNT.
-- 3. How to interpret the output
--    Same interpretation as folder 09 but EBS-scoped.
-- 4. What indicates a problem
--    APPS-only log file sync — chatty forms commits.
-- 5. Recommended DBA action
--    09/17.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT event, wait_class, COUNT(*) cnt
FROM gv$session WHERE username='APPS' AND status='ACTIVE' AND wait_class<>'Idle'
GROUP BY event, wait_class ORDER BY cnt DESC;

PROMPT
PROMPT === End of query: APPS waiters ===
PROMPT

-- End of file
