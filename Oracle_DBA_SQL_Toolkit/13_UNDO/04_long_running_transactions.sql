--------------------------------------------------------------------------------
-- File Name       : 04_long_running_transactions.sql
-- Category        : 13_UNDO
-- Purpose         : Transactions open longer than &minutes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Filters 03 by age. These are 01555 and lock factories.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Long open TX
--------------------------------------------------------------------------------
-- 1. What the query does
--    START_DATE older than threshold.
-- 2. Important columns
--    HOURS_OPEN, USED_UBLK, MODULE.
-- 3. How to interpret the output
--    EBS: a form in a transaction since morning.
-- 4. What indicates a problem
--    Hours-open TX + UNEXPIRED pressure.
-- 5. Recommended DBA action
--    User contact. See 06_Sessions inactive.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$TRANSACTION, GV_$SESSION
--------------------------------------------------------------------------------
DEFINE minutes = 30
SELECT s.inst_id, s.sid, s.serial#, s.username, s.module, s.status,
       t.start_date, ROUND((SYSDATE-t.start_date)*24,2) hours_open,
       t.used_ublk, s.sql_id
FROM gv$transaction t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.ses_addr
WHERE (SYSDATE-t.start_date)*24*60 >= &minutes
ORDER BY t.start_date;

PROMPT
PROMPT === End of query: Long open TX ===
PROMPT

-- End of file
