--------------------------------------------------------------------------------
-- File Name       : 20_ebs_index_growth.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : Largest EBS indexes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Index space on transactional tables. Rebuild only with a plan.
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
-- QUERY 1: Top EBS indexes
--------------------------------------------------------------------------------
-- 1. What the query does
--    INDEX segments.
-- 2. Important columns
--    OWNER, INDEX, GB.
-- 3. How to interpret the output
--    Indexes larger than the table after mass deletes of requests/workflow.
-- 4. What indicates a problem
--    Huge index on a purged table.
-- 5. Recommended DBA action
--    Rebuild ONLINE in a window if fragmentation is proven — change.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT owner, segment_name, ROUND(bytes/1024/1024/1024,2) gb, tablespace_name
FROM dba_segments
WHERE segment_type LIKE 'INDEX%'
AND owner IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Top EBS indexes ===
PROMPT

-- End of file
