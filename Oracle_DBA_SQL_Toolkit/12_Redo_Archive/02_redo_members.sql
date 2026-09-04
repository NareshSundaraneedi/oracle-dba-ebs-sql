--------------------------------------------------------------------------------
-- File Name       : 02_redo_members.sql
-- Category        : 12_Redo_Archive
-- Purpose         : Redo member paths and status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Each group should have 2+ members on independent failure domains.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: V$LOGFILE
--------------------------------------------------------------------------------
-- 1. What the query does
--    Member list.
-- 2. Important columns
--    GROUP#, MEMBER, STATUS.
-- 3. How to interpret the output
--    STATUS NULL is healthy. INVALID/STALE is a problem.
-- 4. What indicates a problem
--    Single member per group.
-- 5. Recommended DBA action
--    ALTER DATABASE ADD LOGFILE MEMBER — change window.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$LOGFILE
--------------------------------------------------------------------------------
SELECT group#, status, type, member, is_recovery_dest_file FROM v$logfile ORDER BY group#, member;

PROMPT
PROMPT === End of query: V$LOGFILE ===
PROMPT

-- End of file
