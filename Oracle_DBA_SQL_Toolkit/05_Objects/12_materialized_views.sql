--------------------------------------------------------------------------------
-- File Name       : 12_materialized_views.sql
-- Category        : 05_Objects
-- Purpose         : MV freshness, compile state, and last refresh
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Stale MVs cause wrong results in reporting. Refresh-on-commit MVs
-- can destroy OLTP performance.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Materialized views
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_MVIEWS.
-- 2. Important columns
--    OWNER, MVIEW_NAME, STALENESS, LAST_REFRESH_DATE, REFRESH_MODE.
-- 3. How to interpret the output
--    STALENESS NEEDS_COMPILE or UNUSABLE is a break. FRESH is good.
-- 4. What indicates a problem
--    REFRESH_MODE COMMIT on a heavy OLTP table.
-- 5. Recommended DBA action
--    Change refresh strategy with the application team. Do not refresh ad hoc during peak unless agreed.
-- 6. Production cautions
--    Safe to query. DBMS_MVIEW.REFRESH is a change/load.
-- 7. Required privileges
--    SELECT on DBA_MVIEWS
--------------------------------------------------------------------------------
SELECT
       owner,
       mview_name,
       compile_state,
       staleness,
       refresh_mode,
       refresh_method,
       last_refresh_date,
       last_refresh_type
FROM   dba_mviews
ORDER BY owner, mview_name;

PROMPT
PROMPT === End of query: Materialized views ===
PROMPT

-- End of file
