--------------------------------------------------------------------------------
-- File Name       : 20_redo_log_files.sql
-- Category        : 01_Basic
-- Purpose         : List redo log groups, members, size, and status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows online redo configuration. Undersized or non-multiplexed redo
-- causes excessive log switches and single points of failure.
-- See also 12_Redo_Archive for rate and contention analysis.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Redo groups and members
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins V$LOG and V$LOGFILE for group, thread, size, members, and status.
-- 2. Important columns
--    GROUP#, THREAD#, SEQUENCE#, BYTES, MEMBERS, STATUS, MEMBER, TYPE.
-- 3. How to interpret the output
--    STATUS CURRENT is the active group. INACTIVE can be checkpointed. Only one CURRENT per thread.
-- 4. What indicates a problem
--    Single member per group. Groups smaller than the redo generation of a few minutes. STATUS STALE or INVALID member.
-- 5. Recommended DBA action
--    Add members on independent disks. Resize redo only during a change window. Never drop the CURRENT group.
-- 6. Production cautions
--    Safe. Redo resize is disruptive and is not performed here.
-- 7. Required privileges
--    SELECT on V_$LOG, V_$LOGFILE
--------------------------------------------------------------------------------
SELECT
       l.group#,
       l.thread#,
       l.sequence#,
       ROUND(l.bytes / 1024 / 1024) AS size_mb,
       l.members,
       l.archived,
       l.status,
       l.first_time
FROM   v$log l
ORDER BY l.thread#, l.group#;

SELECT
       group#,
       status,
       type,
       member,
       is_recovery_dest_file
FROM   v$logfile
ORDER BY group#, member;

PROMPT
PROMPT === End of query: Redo groups and members ===
PROMPT

-- End of file
