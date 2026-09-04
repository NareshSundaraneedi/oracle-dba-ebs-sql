--------------------------------------------------------------------------------
-- File Name       : 13_ebs_temp_usage.sql
-- Category        : 26_EBS_Performance
-- Purpose         : TEMP used by APPS / concurrent sessions
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- TEMPSEG joined to requests when possible.
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
-- QUERY 1: EBS TEMP
--------------------------------------------------------------------------------
-- 1. What the query does
--    tempseg_usage + optional request.
-- 2. Important columns
--    SID, MB, REQUEST_ID, SQL_ID.
-- 3. How to interpret the output
--    Hash spill during Create Accounting is common.
-- 4. What indicates a problem
--    TEMP critical from one request.
-- 5. Recommended DBA action
--    14_TEMP + 25/11.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT t.inst_id, t.sid, t.sql_id, t.segtype, ROUND(t.blocks*8/1024,1) mb, r.request_id
FROM gv$tempseg_usage t
LEFT JOIN fnd_concurrent_requests r ON r.oracle_session_id=t.sid AND r.phase_code='R'
ORDER BY t.blocks DESC;

PROMPT
PROMPT === End of query: EBS TEMP ===
PROMPT

-- End of file
