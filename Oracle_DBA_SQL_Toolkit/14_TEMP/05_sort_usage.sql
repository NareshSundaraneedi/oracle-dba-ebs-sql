--------------------------------------------------------------------------------
-- File Name       : 05_sort_usage.sql
-- Category        : 14_TEMP
-- Purpose         : Sort segment usage only
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Filters TEMP to SEGTYPE SORT. Difference vs 06: hash vs sort have different knobs (join vs ORDER BY/GROUP BY/index create).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SORT temp
--------------------------------------------------------------------------------
-- 1. What the query does
--    SEGTYPE='SORT'.
-- 2. Important columns
--    SID, SQL_ID, MB.
-- 3. How to interpret the output
--    Index create and ORDER BY show here.
-- 4. What indicates a problem
--    Huge sort during CREATE INDEX online.
-- 5. Recommended DBA action
--    Reschedule DDL. Check SORT_AREA / PGA.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION
--------------------------------------------------------------------------------
SELECT t.inst_id, t.sid, s.username, t.sql_id, ROUND(t.blocks*8/1024,1) mb
FROM gv$tempseg_usage t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.session_addr
WHERE t.segtype = 'SORT' ORDER BY t.blocks DESC;

PROMPT
PROMPT === End of query: SORT temp ===
PROMPT

-- End of file
