--------------------------------------------------------------------------------
-- File Name       : 06_hash_usage.sql
-- Category        : 14_TEMP
-- Purpose         : Hash workarea TEMP usage
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- SEGTYPE HASH — typical of HASH JOIN / HASH GROUP BY.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: HASH temp
--------------------------------------------------------------------------------
-- 1. What the query does
--    SEGTYPE='HASH'.
-- 2. Important columns
--    SID, SQL_ID, MB.
-- 3. How to interpret the output
--    Bad join order → huge hash table → TEMP.
-- 4. What indicates a problem
--    Hash spill + high CPU on the same SQL.
-- 5. Recommended DBA action
--    Fix cardinality / join. Not just add TEMP forever.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION
--------------------------------------------------------------------------------
SELECT t.inst_id, t.sid, s.username, t.sql_id, ROUND(t.blocks*8/1024,1) mb
FROM gv$tempseg_usage t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.session_addr
WHERE t.segtype = 'HASH' ORDER BY t.blocks DESC;

PROMPT
PROMPT === End of query: HASH temp ===
PROMPT

-- End of file
