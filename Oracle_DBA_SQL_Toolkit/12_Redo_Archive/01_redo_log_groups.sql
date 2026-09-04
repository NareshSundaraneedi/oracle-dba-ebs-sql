--------------------------------------------------------------------------------
-- File Name       : 01_redo_log_groups.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Redo group configuration
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Group/thread/size/status. Production typically 3+ groups per thread, multiplexed members.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$LOG groups
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$LOG.
-- 2. Important columns
--    GROUP#, THREAD#, BYTES, STATUS, ARCHIVED.
-- 3. How to interpret the output
--    CURRENT is active. ACTIVE still needed for instance recovery.
-- 4. What indicates a problem
--    Only 2 small groups on a busy EBS DB → excessive switches.
-- 5. Recommended DBA action
--    Add groups / resize in a window. Never drop CURRENT.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$LOG
--------------------------------------------------------------------------------
SELECT group#, thread#, sequence#, ROUND(bytes/1024/1024) mb, members, archived, status, first_time
FROM v$log ORDER BY thread#, group#;

PROMPT
PROMPT === End of query: V$LOG groups ===
PROMPT

-- End of file
