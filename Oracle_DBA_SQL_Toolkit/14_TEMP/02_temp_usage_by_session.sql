--------------------------------------------------------------------------------
-- File Name       : 02_temp_usage_by_session.sql
-- Category        : 14_TEMP
-- Purpose         : TEMP by session
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Who is spilling. Difference vs 04/10: this is the TEMP home copy with SEGTYPE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: GV$TEMPSEG_USAGE
--------------------------------------------------------------------------------
-- 1. What the query does
--    Session TEMP.
-- 2. Important columns
--    SID, SQL_ID, MB, SEGTYPE.
-- 3. How to interpret the output
--    HASH vs SORT vs WORK.
-- 4. What indicates a problem
--    One session using most of TEMP.
-- 5. Recommended DBA action
--    Tune SQL or increase PGA to avoid spill.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION
--------------------------------------------------------------------------------
SELECT t.inst_id, t.sid, s.serial#, s.username, s.module, t.sql_id, t.segtype,
       ROUND(t.blocks*8/1024,1) mb
FROM gv$tempseg_usage t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.session_addr
ORDER BY t.blocks DESC;

PROMPT
PROMPT === End of query: GV$TEMPSEG_USAGE ===
PROMPT

-- End of file
