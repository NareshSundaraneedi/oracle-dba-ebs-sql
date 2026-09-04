--------------------------------------------------------------------------------
-- File Name       : 07_archive_gap.sql
-- Category        : 17_DataGuard
-- Purpose         : Gaps on standby
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$ARCHIVE_GAP on the standby. Difference vs 12/08: this is DG-context commentary.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Gaps
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$ARCHIVE_GAP.
-- 2. Important columns
--    THREAD#, LOW, HIGH.
-- 3. How to interpret the output
--    Need those sequences restored and registered.
-- 4. What indicates a problem
--    Any gap.
-- 5. Recommended DBA action
--    RMAN restore archivelog from backup; then apply resumes.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$ARCHIVE_GAP
--------------------------------------------------------------------------------
SELECT thread#, low_sequence#, high_sequence# FROM v$archive_gap;

PROMPT
PROMPT === End of query: Gaps ===
PROMPT

-- End of file
