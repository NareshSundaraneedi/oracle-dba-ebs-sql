--------------------------------------------------------------------------------
-- File Name       : 08_bind_peeking.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : Bind peek / adaptive cursor sharing status for a SQL_ID
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows IS_BIND_SENSITIVE / IS_BIND_AWARE on V$SQL and peeked
-- binds. This is why the same SQL_ID is fast in one concurrent request
-- and slow in another.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Bind-aware cursors
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$SQL bind flags and V$SQL_CS_HISTOGRAM if present.
-- 2. Important columns
--    CHILD_NUMBER, IS_BIND_SENSITIVE, IS_BIND_AWARE, PLAN_HASH.
-- 3. How to interpret the output
--    SENSITIVE but not AWARE means ACS has not kicked in yet. Multiple children with different plans is ACS working.
-- 4. What indicates a problem
--    One peeked bind produced a nested-loop plan that is reused for a high-cardinality bind.
-- 5. Recommended DBA action
--    See 07/16 binds. Consider ACS or a baseline per class of binds.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$SQL
--------------------------------------------------------------------------------
DEFINE sql_id = 0w6u2qj2zn5hs

SELECT
       inst_id,
       child_number,
       plan_hash_value,
       is_bind_sensitive,
       is_bind_aware,
       is_shareable,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s
FROM   gv$sql
WHERE  sql_id = '&sql_id'
ORDER BY inst_id, child_number;

PROMPT
PROMPT === End of query: Bind-aware cursors ===
PROMPT

-- End of file
