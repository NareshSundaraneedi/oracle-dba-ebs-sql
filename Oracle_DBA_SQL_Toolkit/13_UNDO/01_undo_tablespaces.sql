--------------------------------------------------------------------------------
-- File Name       : 01_undo_tablespaces.sql
-- Category        : 13_UNDO
-- Purpose         : Undo tablespaces, files, and retention guarantee
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Lists undo TS and whether RETENTION GUARANTEE is set (can cause ORA-30036 sooner).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Undo TS inventory
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_TABLESPACES contents UNDO.
-- 2. Important columns
--    TABLESPACE_NAME, RETENTION, STATUS.
-- 3. How to interpret the output
--    RETENTION GUARANTEE means expired extents will not be reused — 01555 down, 30036 up.
-- 4. What indicates a problem
--    NO GUARANTEE with frequent 01555 or GUARANTEE with 30036.
-- 5. Recommended DBA action
--    Pick one: more space, or accept the tradeoff.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TABLESPACES, DBA_DATA_FILES
--------------------------------------------------------------------------------
SELECT tablespace_name, status, retention, block_size
FROM dba_tablespaces WHERE contents = 'UNDO';
SELECT tablespace_name, file_name, ROUND(bytes/1024/1024/1024,2) gb, autoextensible
FROM dba_data_files WHERE tablespace_name IN (SELECT tablespace_name FROM dba_tablespaces WHERE contents='UNDO');

PROMPT
PROMPT === End of query: Undo TS inventory ===
PROMPT

-- End of file
