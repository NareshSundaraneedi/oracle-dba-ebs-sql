--------------------------------------------------------------------------------
-- File Name       : 07_sql_by_responsibility.sql
-- Category        : 26_EBS_Performance
-- Purpose         : Active APPS sessions by action/responsibility hint
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- EBS often puts responsibility into ACTION or CLIENT_IDENTIFIER (depending on setup).
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
-- QUERY 1: Action / client_identifier
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$SESSION action and client_identifier for APPS.
-- 2. Important columns
--    ACTION, CLIENT_IDENTIFIER, SQL_ID.
-- 3. How to interpret the output
--    If blank, profile 'Sign-On:Audit Level' / ICX instrumentation may be off.
-- 4. What indicates a problem
--    Cannot map SQL to a responsibility — enable audit/instrumentation as a change.
-- 5. Recommended DBA action
--    Use FND_CONCURRENT_REQUESTS.responsibility_id for batch; forms need instrumentation.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT NVL(action,'(no action)') action, NVL(client_identifier,'(none)') client_identifier,
       COUNT(*) sessions, SUM(DECODE(status,'ACTIVE',1,0)) active
FROM gv$session WHERE username='APPS'
GROUP BY action, client_identifier
ORDER BY active DESC, sessions DESC FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Action / client_identifier ===
PROMPT

-- End of file
