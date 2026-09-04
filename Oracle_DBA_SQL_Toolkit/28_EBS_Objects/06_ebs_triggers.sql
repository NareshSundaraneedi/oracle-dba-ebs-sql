--------------------------------------------------------------------------------
-- File Name       : 06_ebs_triggers.sql
-- Category        : 28_EBS_Objects
-- Purpose         : Triggers on EBS product tables (custom risk)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Triggers owned by XX or APPS on product tables.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Non-SYS triggers on product tables
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_TRIGGERS.
-- 2. Important columns
--    TABLE_NAME, TRIGGER_NAME, STATUS.
-- 3. How to interpret the output
--    Custom triggers on GL/AR tables are performance and upgrade risks.
-- 4. What indicates a problem
--    Enabled custom trigger on a hot table after a go-live.
-- 5. Recommended DBA action
--    Review code. Disable only with approval — generated not here.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TRIGGERS
--------------------------------------------------------------------------------
SELECT owner, trigger_name, table_owner, table_name, status, triggering_event
FROM dba_triggers
WHERE table_owner IN (SELECT oracle_username FROM fnd_oracle_userid)
AND owner NOT IN ('SYS','SYSTEM')
ORDER BY table_owner, table_name;

PROMPT
PROMPT === End of query: Non-SYS triggers on product tables ===
PROMPT

-- End of file
