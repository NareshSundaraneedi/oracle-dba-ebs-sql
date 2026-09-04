--------------------------------------------------------------------------------
-- File Name       : 10_sessions_by_sql_id.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Which SQL_IDs are being executed right now
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Groups ACTIVE sessions by SQL_ID to find a stampeding query.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Active sessions per SQL_ID
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates ACTIVE GV$SESSION by SQL_ID.
-- 2. Important columns
--    SQL_ID, SESSIONS, SAMPLE_TEXT.
-- 3. How to interpret the output
--    Many sessions / one SQL_ID = plan issue or missing bind peek / data skew.
-- 4. What indicates a problem
--    A reporting SQL_ID with 40 sessions during peak.
-- 5. Recommended DBA action
--    Take the SQL_ID to 08_SQL_Tuning.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$SQL
--------------------------------------------------------------------------------
SELECT
       s.sql_id,
       COUNT(*) AS sessions,
       MIN(s.event) AS sample_event,
       MIN(SUBSTR(q.sql_text,1,120)) AS sql_text
FROM   gv$session s
LEFT JOIN gv$sql q
       ON q.inst_id = s.inst_id AND q.sql_id = s.sql_id AND q.child_number = s.sql_child_number
WHERE  s.status = 'ACTIVE'
AND    s.sql_id IS NOT NULL
GROUP BY s.sql_id
ORDER BY sessions DESC;

PROMPT
PROMPT === End of query: Active sessions per SQL_ID ===
PROMPT

-- End of file
