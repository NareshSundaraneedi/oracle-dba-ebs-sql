--------------------------------------------------------------------------------
-- File Name       : 18_ebs_schema_growth.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : EBS schema sizes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DBA_SEGMENTS for FND oracle users. Find which product is growing.
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
-- QUERY 1: Schema GB
--------------------------------------------------------------------------------
-- 1. What the query does
--    Sum segments.
-- 2. Important columns
--    OWNER, GB.
-- 3. How to interpret the output
--    APPLSYS + GL + custom XX often dominate.
-- 4. What indicates a problem
--    One schema jumped vs last month's health check.
-- 5. Recommended DBA action
--    19/20 table and index growth.
-- 6. Production cautions
--    Safe. Slight dictionary cost.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS
--------------------------------------------------------------------------------
SELECT owner, ROUND(SUM(bytes)/1024/1024/1024,2) gb, COUNT(*) segments
FROM dba_segments
WHERE owner IN (SELECT oracle_username FROM fnd_oracle_userid)
GROUP BY owner
ORDER BY gb DESC;

PROMPT
PROMPT === End of query: Schema GB ===
PROMPT

-- End of file
