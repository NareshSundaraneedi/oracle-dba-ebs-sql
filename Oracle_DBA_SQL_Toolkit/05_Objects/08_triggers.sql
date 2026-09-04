--------------------------------------------------------------------------------
-- File Name       : 08_triggers.sql
-- Category        : 05_Objects
-- Purpose         : List enabled triggers (performance and mutating-table suspects)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Row-level triggers on busy EBS tables are a common source of
-- unexpected CPU and waits. Inventory first, then inspect code.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Non-system triggers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_TRIGGERS excluding SYS.
-- 2. Important columns
--    OWNER, TRIGGER_NAME, TABLE_NAME, STATUS, TRIGGERING_EVENT.
-- 3. How to interpret the output
--    ENABLED AFTER ROW on a high-DML table is a performance suspect.
-- 4. What indicates a problem
--    A custom trigger introduced last night on GL_JE_LINES.
-- 5. Recommended DBA action
--    Review trigger body. Disable only with application approval — generated only.
-- 6. Production cautions
--    WARNING: DISABLE generated only.
-- 7. Required privileges
--    SELECT on DBA_TRIGGERS
-- EBS relevance  : Useful for EBS
--------------------------------------------------------------------------------
SELECT
       owner,
       trigger_name,
       table_owner,
       table_name,
       triggering_event,
       trigger_type,
       status
FROM   dba_triggers
WHERE  owner NOT IN ('SYS','SYSTEM','XDB')
ORDER BY table_owner, table_name, trigger_name;

PROMPT
PROMPT === End of query: Non-system triggers ===
PROMPT

-- End of file
