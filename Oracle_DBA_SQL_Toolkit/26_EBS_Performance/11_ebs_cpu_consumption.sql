--------------------------------------------------------------------------------
-- File Name       : 11_ebs_cpu_consumption.sql
-- Category        : 26_EBS_Performance
-- Purpose         : CPU by APPS session (SESSTAT)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Cumulative CPU — pair with last_call_et.
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
-- QUERY 1: APPS CPU
--------------------------------------------------------------------------------
-- 1. What the query does
--    CPU used by this session for APPS.
-- 2. Important columns
--    SID, CPU_S, SQL_ID, MODULE.
-- 3. How to interpret the output
--    Long-lived forms accumulate CPU — sort by last_call_et too.
-- 4. What indicates a problem
--    One sid burning CPU on a custom package.
-- 5. Recommended DBA action
--    25/08.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT s.sid, s.serial#, s.module, s.sql_id, s.last_call_et, ROUND(st.value/100,1) cpu_s
FROM gv$session s
JOIN gv$sesstat st ON st.inst_id=s.inst_id AND st.sid=s.sid
JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE sn.name='CPU used by this session' AND s.username='APPS'
ORDER BY st.value DESC FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: APPS CPU ===
PROMPT

-- End of file
