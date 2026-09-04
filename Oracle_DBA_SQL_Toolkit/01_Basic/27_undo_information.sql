--------------------------------------------------------------------------------
-- File Name       : 27_undo_information.sql
-- Category        : 01_Basic
-- Purpose         : Show undo tablespace, retention, and basic usage
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Quick undo health. Deep ORA-01555 / ORA-30036 analysis is in 13_UNDO.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Undo configuration and usage
--------------------------------------------------------------------------------
-- 1. What the query does
--    Shows undo_tablespace, undo_retention, and DBA_UNDO_EXTENTS summary.
-- 2. Important columns
--    UNDO_TABLESPACE, UNDO_RETENTION, STATUS extents, TUNED_UNDORETENTION.
-- 3. How to interpret the output
--    ACTIVE extents are in-use by transactions. UNEXPIRED are retained for consistent read. EXPIRED can be reused.
-- 4. What indicates a problem
--    No EXPIRED space and UNEXPIRED being stolen — risk of ORA-01555. Undo tablespace 95%+ used.
-- 5. Recommended DBA action
--    Increase undo tablespace or undo_retention only after checking long-running transactions.
-- 6. Production cautions
--    Safe. Changing undo_retention affects flashback query and EBS long reports.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$UNDOSTAT, DBA_UNDO_EXTENTS, DBA_TABLESPACES
--------------------------------------------------------------------------------
SELECT name, value
FROM   v$parameter
WHERE  name IN ('undo_tablespace','undo_management','undo_retention');

SELECT
       tablespace_name,
       status,
       COUNT(*) AS extents,
       ROUND(SUM(bytes) / 1024 / 1024, 1) AS mb
FROM   dba_undo_extents
GROUP BY tablespace_name, status
ORDER BY tablespace_name, status;

SELECT
       TO_CHAR(begin_time, 'DD-MON-RR HH24:MI') AS begin_time,
       undoblks,
       txncount,
       maxquerylen,
       maxqueryid,
       tuned_undoretention,
       ssolderrcnt,
       nospaceerrcnt
FROM   v$undostat
WHERE  begin_time > SYSDATE - 1 / 24
ORDER BY begin_time DESC;

PROMPT
PROMPT === End of query: Undo configuration and usage ===
PROMPT

-- End of file
