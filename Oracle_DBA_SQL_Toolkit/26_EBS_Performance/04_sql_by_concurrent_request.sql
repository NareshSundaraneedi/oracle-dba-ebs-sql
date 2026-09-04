--------------------------------------------------------------------------------
-- File Name       : 04_sql_by_concurrent_request.sql
-- Category        : 26_EBS_Performance
-- Purpose         : SQL_ID for one request_id (performance folder shortcut)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DEFINE request_id. Difference vs 25/03: includes sql_text in one step.
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
-- QUERY 1: SQL for a request
--------------------------------------------------------------------------------
-- 1. What the query does
--    Join request to gv$sql via session.
-- 2. Important columns
--    REQUEST_ID, SQL_ID, SQL_TEXT.
-- 3. How to interpret the output
--    Empty SQL means not in a DB call.
-- 4. What indicates a problem
--    N/A lookup.
-- 5. Recommended DBA action
--    05 plan.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
DEFINE request_id = 0
SELECT r.request_id, s.sql_id, s.event, SUBSTR(q.sql_text,1,200) sql_text
FROM fnd_concurrent_requests r
LEFT JOIN gv$session s ON s.sid=r.oracle_session_id
LEFT JOIN gv$sql q ON q.inst_id=s.inst_id AND q.sql_id=s.sql_id AND q.child_number=s.sql_child_number
WHERE r.request_id=&request_id;

PROMPT
PROMPT === End of query: SQL for a request ===
PROMPT

-- End of file
