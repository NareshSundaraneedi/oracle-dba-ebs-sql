--------------------------------------------------------------------------------
-- File Name       : 06_disabled_constraints.sql
-- Category        : 05_Objects
-- Purpose         : List disabled constraints
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Disabled PK/UK/FK after a data load that never re-enabled them is
-- a data-integrity incident.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Disabled constraints
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_CONSTRAINTS where STATUS = DISABLED.
-- 2. Important columns
--    OWNER, CONSTRAINT_NAME, CONSTRAINT_TYPE, TABLE_NAME, STATUS.
-- 3. How to interpret the output
--    TYPE P/U/R/C. NOVAlIDATE enabled is different (not listed here).
-- 4. What indicates a problem
--    Disabled PK on a transactional table.
-- 5. Recommended DBA action
--    ENABLE is a change and will validate data. Generated only.
-- 6. Production cautions
--    WARNING: ENABLE can fail on bad data and locks the table. Generated only.
-- 7. Required privileges
--    SELECT on DBA_CONSTRAINTS
--------------------------------------------------------------------------------
SELECT owner, constraint_name, constraint_type, table_name, status, validated, last_change
FROM   dba_constraints
WHERE  status = 'DISABLED'
AND    owner NOT IN ('SYS','SYSTEM')
ORDER BY owner, table_name;

-- WARNING: Review carefully. May fail if child/parent data is inconsistent.
SELECT 'ALTER TABLE "'||owner||'"."'||table_name||'" ENABLE CONSTRAINT "'||constraint_name||'";' AS enable_cmd
FROM   dba_constraints
WHERE  status = 'DISABLED'
AND    owner NOT IN ('SYS','SYSTEM');

PROMPT
PROMPT === End of query: Disabled constraints ===
PROMPT

-- End of file
