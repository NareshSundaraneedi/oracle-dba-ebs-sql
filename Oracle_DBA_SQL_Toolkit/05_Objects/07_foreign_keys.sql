--------------------------------------------------------------------------------
-- File Name       : 07_foreign_keys.sql
-- Category        : 05_Objects
-- Purpose         : Find foreign keys without supporting indexes (parent update / child delete risk)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Unindexed FKs cause TM lock waits (enq: TM - contention) when the
-- parent is updated/deleted. Classic EBS customization issue.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: FK columns missing a leading index
--------------------------------------------------------------------------------
-- 1. What the query does
--    Compares DBA_CONS_COLUMNS of referential constraints to DBA_IND_COLUMNS.
-- 2. Important columns
--    OWNER, TABLE_NAME, CONSTRAINT_NAME, COLUMNS.
-- 3. How to interpret the output
--    An index that starts with the FK columns is sufficient. This query flags FKs with no such index.
-- 4. What indicates a problem
--    enq: TM - contention on the child table during parent deletes.
-- 5. Recommended DBA action
--    Create an index on the FK columns after reviewing cardinality. Change request required.
-- 6. Production cautions
--    Safe to query. Index create is a change.
-- 7. Required privileges
--    SELECT on DBA_CONSTRAINTS, DBA_CONS_COLUMNS, DBA_IND_COLUMNS
--------------------------------------------------------------------------------
SELECT
       c.owner,
       c.table_name,
       c.constraint_name,
       LISTAGG(cc.column_name, ',') WITHIN GROUP (ORDER BY cc.position) AS fk_cols
FROM   dba_constraints c
JOIN   dba_cons_columns cc
       ON cc.owner = c.owner AND cc.constraint_name = c.constraint_name
WHERE  c.constraint_type = 'R'
AND    c.owner NOT IN ('SYS','SYSTEM')
AND    NOT EXISTS (
         SELECT 1
         FROM   dba_ind_columns ic
         WHERE  ic.table_owner = c.owner
         AND    ic.table_name  = c.table_name
         AND    ic.column_position = 1
         AND    ic.column_name = (
                  SELECT column_name FROM dba_cons_columns
                  WHERE  owner = c.owner AND constraint_name = c.constraint_name AND position = 1
                )
       )
GROUP BY c.owner, c.table_name, c.constraint_name
ORDER BY c.owner, c.table_name;

PROMPT
PROMPT === End of query: FK columns missing a leading index ===
PROMPT

-- End of file
