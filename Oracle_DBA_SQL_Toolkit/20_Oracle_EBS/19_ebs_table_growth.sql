--------------------------------------------------------------------------------
-- File Name       : 19_ebs_table_growth.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Largest EBS tables
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Top tables in EBS schemas — purge candidates (WF, FND_LOG, interface, audit).
--
-- Requires EBS R12.2 objects (APPLSYS/APPS). Will fail on a non-EBS database.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Top EBS tables
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_SEGMENTS TABLE%.
-- 2. Important columns
--    OWNER, TABLE, GB.
-- 3. How to interpret the output
--    FND_CONCURRENT_REQUESTS, WF_ITEM_ACTIVITY_STATUSES_H, GL_JE_LINES commonly large.
-- 4. What indicates a problem
--    Interface table in top 10.
-- 5. Recommended DBA action
--    Purge concurrent requests / workflow / interface with standard EBS purge programs — not TRUNCATE unless approved.
-- 6. Production cautions
--    WARNING: No TRUNCATE generated as auto-run.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT owner, segment_name, ROUND(bytes/1024/1024/1024,2) gb, tablespace_name
FROM dba_segments
WHERE segment_type LIKE 'TABLE%'
AND owner IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Top EBS tables ===
PROMPT

-- End of file
