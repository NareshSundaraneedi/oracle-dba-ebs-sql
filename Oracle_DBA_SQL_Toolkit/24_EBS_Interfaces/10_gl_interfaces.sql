--------------------------------------------------------------------------------
-- File Name       : 10_gl_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : GL_INTERFACE / Journal Import
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- STATUS NEW is unimported. Journal Import (GLLEZL) groups by GL_INTERFACE_CONTROL.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: GL interface
--------------------------------------------------------------------------------
-- 1. What the query does
--    Status and set_of_books / ledger backlog.
-- 2. Important columns
--    STATUS, LEDGER_ID, CNT.
-- 3. How to interpret the output
--    STATUS other than NEW after import may be processed or error (site-specific codes).
-- 4. What indicates a problem
--    NEW rows older than the last successful Journal Import.
-- 5. Recommended DBA action
--    Run Journal Import for that group_id. Check GL_INTERFACE_CONTROL.
-- 6. Production cautions
--    COUNT(*) on GL_INTERFACE can be expensive — grouped query uses the table once.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT status, set_of_books_id, ledger_id, user_je_source_name, COUNT(*) cnt,
       MIN(accounting_date) min_gl_date, MAX(accounting_date) max_gl_date
FROM gl_interface
GROUP BY status, set_of_books_id, ledger_id, user_je_source_name
ORDER BY cnt DESC;

SELECT * FROM gl_interface_control
ORDER BY je_source_name;

PROMPT
PROMPT === End of query: GL interface ===
PROMPT

-- End of file
