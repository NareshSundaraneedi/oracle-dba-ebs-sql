--------------------------------------------------------------------------------
-- File Name       : 09_check_logical_reads.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 9 — logical I/O (buffer gets)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- session logical reads / consistent gets. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Step 9 — logical I/O (buffer gets)
--------------------------------------------------------------------------------
-- 1. What the query does
--    session logical reads / consistent gets.
-- 2. Important columns
--    See SELECT list.
-- 3. How to interpret the output
--    Capture the output into the incident ticket before changing anything.
-- 4. What indicates a problem
--    Missing session or SQL_ID means the program is not in a DB call — check the request log.
-- 5. Recommended DBA action
--    Continue the next numbered script. Do not skip to kill.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
DEFINE sid = 0
DEFINE inst = 1
SELECT sn.name, st.value
FROM gv$sesstat st JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE st.inst_id=&inst AND st.sid=&sid
AND sn.name IN ('session logical reads','consistent gets','db block gets','buffer is pinned count');

PROMPT
PROMPT === End of query: Step 9 — logical I/O (buffer gets) ===
PROMPT

-- End of file
