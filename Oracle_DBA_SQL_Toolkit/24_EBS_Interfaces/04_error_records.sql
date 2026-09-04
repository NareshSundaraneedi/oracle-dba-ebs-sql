--------------------------------------------------------------------------------
-- File Name       : 04_error_records.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Sample error messages (not just counts)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows a few error texts so you can classify data vs program bugs.
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
-- QUERY 1: Sample errors
--------------------------------------------------------------------------------
-- 1. What the query does
--    Picks error columns from PO, MTL, AP.
-- 2. Important columns
--    TABLE, KEY, ERROR.
-- 3. How to interpret the output
--    ORA- errors vs APP- / functional rejection.
-- 4. What indicates a problem
--    All errors the same APP- message = data contract broken.
-- 5. Recommended DBA action
--    Fix source data. Do not loop UPDATE status to NEW without fixing columns.
-- 6. Production cautions
--    FETCH FIRST only.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT 'PO' src, interface_transaction_id key, error_message FROM po_interface_errors
ORDER BY creation_date DESC FETCH FIRST 20 ROWS ONLY;

SELECT 'MTL' src, transaction_interface_id key, error_code||' '||error_explanation
FROM mtl_transactions_interface
WHERE error_code IS NOT NULL
FETCH FIRST 20 ROWS ONLY;

SELECT 'AP' src, invoice_id key, status||' '||reject_lookup_code
FROM ap_invoices_interface
WHERE NVL(status,'NEW') IN ('REJECTED','ERROR')
FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: Sample errors ===
PROMPT

-- End of file
