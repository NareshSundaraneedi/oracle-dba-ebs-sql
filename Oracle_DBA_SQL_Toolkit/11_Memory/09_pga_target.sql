--------------------------------------------------------------------------------
-- File Name       : 09_pga_target.sql
-- Category        : 11_Memory
-- Purpose         : PGA targets and limit
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- pga_aggregate_target is a goal. pga_aggregate_limit (12c+) is a hard cap (ORA-04036).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: PGA parameters
--------------------------------------------------------------------------------
-- 1. What the query does
--    V$PARAMETER PGA settings.
-- 2. Important columns
--    PGA_AGGREGATE_TARGET, PGA_AGGREGATE_LIMIT, WORKAREA_SIZE_POLICY.
-- 3. How to interpret the output
--    WORKAREA_SIZE_POLICY should be AUTO on 19c.
-- 4. What indicates a problem
--    LIMIT too close to TARGET causing 4036 during month-end.
-- 5. Recommended DBA action
--    Raise LIMIT carefully (it is a cap on process PGA, affects OS RAM).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on V_$PARAMETER
--------------------------------------------------------------------------------
SELECT name, display_value FROM v$parameter
WHERE name IN ('pga_aggregate_target','pga_aggregate_limit','workarea_size_policy','hash_area_size','sort_area_size','memory_target');

PROMPT
PROMPT === End of query: PGA parameters ===
PROMPT

-- End of file
