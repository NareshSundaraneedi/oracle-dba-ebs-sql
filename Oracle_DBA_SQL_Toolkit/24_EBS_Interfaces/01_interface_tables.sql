--------------------------------------------------------------------------------
-- File Name       : 01_interface_tables.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Catalog of common R12.2 interface tables and current row counts
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Counts only — cheap if stats exist; otherwise COUNT(*) on huge interfaces can be expensive. Uses NUM_ROWS from stats as an estimate plus optional live count for small tables.
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
-- QUERY 1: Interface table estimates
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_TABLES num_rows for well-known interface tables.
-- 2. Important columns
--    OWNER, TABLE_NAME, NUM_ROWS, LAST_ANALYZED.
-- 3. How to interpret the output
--    NUM_ROWS is only as good as stats. A table with millions of rows and last_analyzed months ago needs a live count in a window.
-- 4. What indicates a problem
--    Interface table estimated in the millions — purge/process overdue.
-- 5. Recommended DBA action
--    Module-specific scripts 08-15. Do not TRUNCATE.
-- 6. Production cautions
--    Avoid COUNT(*) on multi-GB tables during peak.
-- 7. Required privileges
--    SELECT on DBA_TABLES
--------------------------------------------------------------------------------
SELECT owner, table_name, num_rows, last_analyzed, blocks
FROM dba_tables
WHERE table_name IN (
  'AP_INVOICES_INTERFACE','AP_INVOICE_LINES_INTERFACE',
  'RA_INTERFACE_LINES_ALL','RA_INTERFACE_DISTRIBUTIONS_ALL','RA_INTERFACE_SALESCREDITS_ALL',
  'GL_INTERFACE','GL_INTERFACE_HISTORY','GL_INTERFACE_CONTROL',
  'PO_HEADERS_INTERFACE','PO_LINES_INTERFACE','PO_INTERFACE_ERRORS',
  'MTL_TRANSACTIONS_INTERFACE','MTL_TRANSACTION_LOTS_INTERFACE','MTL_SERIAL_NUMBERS_INTERFACE',
  'MTL_SYSTEM_ITEMS_INTERFACE','MTL_ITEM_CATEGORIES_INTERFACE',
  'OE_HEADERS_IFACE_ALL','OE_LINES_IFACE_ALL','OE_PAYMENTS_IFACE_ALL',
  'HR_API_TRANSACTIONS','PER_ALL_ASSIGNMENTS_F',
  'PA_TRANSACTION_INTERFACE_ALL'
)
ORDER BY NVL(num_rows,0) DESC;

PROMPT
PROMPT === End of query: Interface table estimates ===
PROMPT

-- End of file
