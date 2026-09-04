--------------------------------------------------------------------------------
-- File Name       : 11_undo_usage.sql
-- Category        : 04_Tablespaces_Datafiles
-- Purpose         : Undo tablespace usage snapshot (storage view)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Storage-centric undo usage. Transaction-centric analysis is in 13_UNDO.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Undo space by extent status
--------------------------------------------------------------------------------
-- 1. What the query does
--    Aggregates DBA_UNDO_EXTENTS and file usage.
-- 2. Important columns
--    STATUS, MB, TABLESPACE_NAME.
-- 3. How to interpret the output
--    EXPIRED is reusable. UNEXPIRED can be reused under space pressure (risking ORA-01555).
-- 4. What indicates a problem
--    Almost no EXPIRED and tablespace 95% used.
-- 5. Recommended DBA action
--    Add undo space or kill/finish a long transaction (13_UNDO).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_UNDO_EXTENTS, DBA_DATA_FILES
--------------------------------------------------------------------------------
SELECT tablespace_name, status,
       ROUND(SUM(bytes)/1024/1024,1) AS mb,
       COUNT(*) AS extents
FROM   dba_undo_extents
GROUP BY tablespace_name, status
ORDER BY tablespace_name, status;

PROMPT
PROMPT === End of query: Undo space by extent status ===
PROMPT

-- End of file
