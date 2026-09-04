--------------------------------------------------------------------------------
-- File Name       : 09_ebs_active_sessions.sql
-- Category        : 26_EBS_Performance
-- Purpose         : All ACTIVE APPS sessions with request mapping when possible
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Left join to running requests.
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
-- QUERY 1: Active APPS + request_id
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SESSION APPS ACTIVE left join FND_CONCURRENT_REQUESTS.
-- 2. Important columns
--    SID, MODULE, REQUEST_ID, SQL_ID, EVENT.
-- 3. How to interpret the output
--    No request_id = Forms/OAF/other.
-- 4. What indicates a problem
--    Many active without module — uninstrumented custom.
-- 5. Recommended DBA action
--    Identify program from SQL.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT s.inst_id, s.sid, s.serial#, s.module, s.sql_id, s.event, s.last_call_et, r.request_id
FROM gv$session s
LEFT JOIN fnd_concurrent_requests r ON r.oracle_session_id=s.sid AND r.phase_code='R'
WHERE s.username='APPS' AND s.status='ACTIVE'
ORDER BY s.last_call_et DESC;

PROMPT
PROMPT === End of query: Active APPS + request_id ===
PROMPT

-- End of file
