--------------------------------------------------------------------------------
-- File Name       : 14_failover_readiness.sql
-- Category        : 17_DataGuard
-- Purpose         : Failover readiness and FSFO observer notes
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Failover is destructive to unapplied primary redo if the old primary is lost. This only checks configuration health.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: FSFO / failover-related flags
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$DATABASE FS_FAILOVER columns if present + dest sync.
-- 2. Important columns
--    FS_FAILOVER_STATUS, FS_FAILOVER_CURRENT_TARGET.
-- 3. How to interpret the output
--    UNOBSERVED means observer is down — FSFO will not fire.
-- 4. What indicates a problem
--    Observer down in a FSFO config.
-- 5. Recommended DBA action
--    Restart observer. Do not FAILOVER from SQL without incident command.
-- 6. Production cautions
--    Safe. No FAILOVER executed.
-- 7. Required privileges
--    SELECT on V_$DATABASE
--------------------------------------------------------------------------------
SELECT database_role, protection_mode, fs_failover_status, fs_failover_current_target,
       fs_failover_observer_present, fs_failover_observer_host
FROM v$database;
PROMPT DGMGRL: SHOW FAST_START FAILOVER;

PROMPT
PROMPT === End of query: FSFO / failover-related flags ===
PROMPT

-- End of file
