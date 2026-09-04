--------------------------------------------------------------------------------
-- File Name       : 02_undo_usage.sql
-- Category        : 13_UNDO
-- Purpose         : Undo extent status and file fill
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- ACTIVE/UNEXPIRED/EXPIRED breakdown. Difference vs 04/11: this is the undo DBA home view.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Extent status
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_UNDO_EXTENTS.
-- 2. Important columns
--    STATUS, MB.
-- 3. How to interpret the output
--    EXPIRED reusable. Steal of UNEXPIRED risks 01555.
-- 4. What indicates a problem
--    EXPIRED ≈ 0 and files 95%+.
-- 5. Recommended DBA action
--    Add file or finish long transactions (04).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_UNDO_EXTENTS
--------------------------------------------------------------------------------
SELECT tablespace_name, status, COUNT(*) extents, ROUND(SUM(bytes)/1024/1024,1) mb
FROM dba_undo_extents GROUP BY tablespace_name, status;

PROMPT
PROMPT === End of query: Extent status ===
PROMPT

-- End of file
