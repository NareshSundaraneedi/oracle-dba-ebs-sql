--------------------------------------------------------------------------------
-- File Name       : 12_ebs_io.sql
-- Category        : 26_EBS_Performance
-- Purpose         : Physical I/O by APPS session
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Cumulative physical reads.
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
-- QUERY 1: APPS physical reads
--------------------------------------------------------------------------------
-- 1. What the query does
--    SESSTAT physical reads for APPS.
-- 2. Important columns
--    SID, PHY_READS, SQL_ID.
-- 3. How to interpret the output
--    Reporting concurrent programs dominate.
-- 4. What indicates a problem
--    OLTP form with huge physical reads.
-- 5. Recommended DBA action
--    FTS/plan.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT s.sid, s.module, s.sql_id, st.value phy_reads
FROM gv$session s
JOIN gv$sesstat st ON st.inst_id=s.inst_id AND st.sid=s.sid
JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE sn.name='physical reads' AND s.username='APPS'
ORDER BY st.value DESC FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: APPS physical reads ===
PROMPT

-- End of file
