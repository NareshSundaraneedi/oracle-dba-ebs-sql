--------------------------------------------------------------------------------
-- File Name       : 11_po_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Purchasing document open interface
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- PO_HEADERS_INTERFACE / PO_LINES_INTERFACE / PO_INTERFACE_ERRORS. Import Standard Purchase Orders.
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
-- QUERY 1: PO interface errors and headers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Error table plus header process status.
-- 2. Important columns
--    INTERFACE_HEADER_ID, PROCESS_CODE, ERROR_MESSAGE.
-- 3. How to interpret the output
--    PROCESS_CODE PENDING/ACCEPTED/REJECTED (confirm on site).
-- 4. What indicates a problem
--    Errors on a high-volume punchout/XML gateway feed.
-- 5. Recommended DBA action
--    Read PO_INTERFACE_ERRORS. Fix data. Rerun Import.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT process_code, COUNT(*) cnt FROM po_headers_interface
GROUP BY process_code;

SELECT interface_header_id, table_name, column_name, error_message, creation_date
FROM po_interface_errors
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: PO interface errors and headers ===
PROMPT

-- End of file
