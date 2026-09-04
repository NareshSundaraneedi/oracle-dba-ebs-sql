--------------------------------------------------------------------------------
-- File Name       : 03_active_undo.sql
-- Category        : 13_UNDO
-- Purpose         : Who holds ACTIVE undo (open transactions)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Joins V$TRANSACTION to sessions.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Active transactions
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$TRANSACTION + GV$SESSION.
-- 2. Important columns
--    USED_UREC, USED_UBLK, START_TIME, SID, SQL_ID.
-- 3. How to interpret the output
--    USED_UBLK large = a big uncommitted DML.
-- 4. What indicates a problem
--    A transaction open for hours with many waiters (locks) or 01555 victims.
-- 5. Recommended DBA action
--    Ask for commit/rollback. DISCONNECT POST_TRANSACTION if appropriate.
-- 6. Production cautions
--    Safe. Do not kill a payroll post without approval.
-- 7. Required privileges
--    SELECT on GV_$TRANSACTION, GV_$SESSION
--------------------------------------------------------------------------------
SELECT t.inst_id, t.addr, t.status, t.start_date,
       t.used_ublk, t.used_urec, t.xid,
       s.sid, s.serial#, s.username, s.status sess_status,
       s.module, s.sql_id, s.event
FROM gv$transaction t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.ses_addr
ORDER BY t.used_ublk DESC;

PROMPT
PROMPT === End of query: Active transactions ===
PROMPT

-- End of file
