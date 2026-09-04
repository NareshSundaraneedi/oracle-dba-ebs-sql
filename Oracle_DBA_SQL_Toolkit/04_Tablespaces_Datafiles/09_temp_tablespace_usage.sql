--------------------------------------------------------------------------------
-- File Name       : 09_temp_tablespace_usage.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Temporary tablespace usage (summary)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Instance-level TEMP usage. Session-level detail is in 14_TEMP.
-- On RAC, each instance has its own TEMP usage — use GV$ views.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: TEMP usage by instance
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads GV$TEMP_SPACE_HEADER and GV$TEMP_EXTENT_POOL / DBA_TEMP_FREE_SPACE.
-- 2. Important columns
--    TABLESPACE_NAME, TOTAL_GB, USED_GB, FREE_GB.
-- 3. How to interpret the output
--    USED high during Gather Stats or a hash join is expected and should drop after the statement.
-- 4. What indicates a problem
--    USED stuck near TOTAL after the statement ended — extents not yet released (they are reusable) or a still-open sort.
-- 5. Recommended DBA action
--    Find the session in 14_TEMP. Do not shrink TEMP during the incident.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TEMP_FREE_SPACE, GV_$SORT_SEGMENT
--------------------------------------------------------------------------------
SELECT
       tablespace_name,
       ROUND(tablespace_size/1024/1024/1024,2) AS total_gb,
       ROUND(allocated_space/1024/1024/1024,2) AS allocated_gb,
       ROUND(free_space/1024/1024/1024,2) AS free_gb
FROM   dba_temp_free_space;

SELECT
       inst_id,
       tablespace_name,
       ROUND(total_blocks * 8 / 1024 / 1024, 2) AS total_gb_approx_8k,
       ROUND(used_blocks * 8 / 1024 / 1024, 2) AS used_gb_approx_8k
FROM   gv$sort_segment
ORDER BY inst_id, tablespace_name;

PROMPT
PROMPT === End of query: TEMP usage by instance ===
PROMPT

-- End of file
