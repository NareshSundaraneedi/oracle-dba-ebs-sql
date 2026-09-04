--------------------------------------------------------------------------------
-- File Name       : 04_redo_log_status.sql
-- Category        : 12_Redo_Archive
-- Purpose         : All group statuses including CLEARING/UNUSED
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- CLEARING after an incomplete recovery. UNUSED after add.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Status histogram
--------------------------------------------------------------------------------
-- 1. What the query does
--    Count by status.
-- 2. Important columns
--    STATUS, CNT.
-- 3. How to interpret the output
--    Multiple CURRENT on one thread is wrong (except transient).
-- 4. What indicates a problem
--    CLEARING stuck.
-- 5. Recommended DBA action
--    Alert log. Do not clear logs without Support if in doubt.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$LOG
--------------------------------------------------------------------------------
SELECT status, COUNT(*) cnt FROM v$log GROUP BY status;
SELECT * FROM v$log ORDER BY thread#, group#;

PROMPT
PROMPT === End of query: Status histogram ===
PROMPT

-- End of file
