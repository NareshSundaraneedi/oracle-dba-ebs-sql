--------------------------------------------------------------------------------
-- File Name       : 16_bind_variables.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Inspect bind values captured for a SQL_ID
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- V$SQL_BIND_CAPTURE shows peeked/captured binds. Peeking + skew
-- is a top cause of intermittent bad plans in EBS.
--
-- LICENSING: V$SQL_BIND_CAPTURE is EE dictionary. AWR bind capture history is Diagnostics Pack (DBA_HIST_SQLBIND).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Captured binds for &sql_id
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$SQL_BIND_CAPTURE.
-- 2. Important columns
--    NAME, DATATYPE_STRING, VALUE_STRING, LAST_CAPTURED.
-- 3. How to interpret the output
--    VALUE_STRING may be truncated. DATATYPE mismatches cause implicit conversion and index suppression.
-- 4. What indicates a problem
--    A bind of '%' or NULL changing cardinality.
-- 5. Recommended DBA action
--    Check histograms / bind-aware cursor sharing (adaptive cursor sharing).
-- 6. Production cautions
--    Safe. Binds may contain sensitive data — handle output as confidential.
-- 7. Required privileges
--    SELECT on V_$SQL_BIND_CAPTURE
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs

SELECT
       sql_id,
       child_number,
       name,
       position,
       datatype_string,
       value_string,
       last_captured
FROM   v$sql_bind_capture
WHERE  sql_id = '&sql_id'
ORDER BY child_number, position;

PROMPT
PROMPT === End of query: Captured binds for &sql_id ===
PROMPT

-- End of file
