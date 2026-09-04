--------------------------------------------------------------------------------
-- File Name       : 02_failed_interface_records.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Generic pattern: records with ERROR / REJECTED status across modules
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Each module uses different status columns. This script points you at the module files and shows AP/AR/GL/PO error counts.
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
-- QUERY 1: Error counts by module interface
--------------------------------------------------------------------------------
-- 1. What the query does
--    Status-based counts on the most common tables.
-- 2. Important columns
--    SOURCE, ERROR_COUNT.
-- 3. How to interpret the output
--    Any non-zero ERROR after a load window is a functional + technical ticket.
-- 4. What indicates a problem
--    Error count growing — import program not running or data systematically bad.
-- 5. Recommended DBA action
--    Open the module script (08+). Process via the standard import concurrent program, not SQL UPDATE of status.
-- 6. Production cautions
--    Queries filter STATUS — still can be heavy. Run off-peak if tables are huge.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT 'AP_INVOICES_INTERFACE' src, COUNT(*) cnt FROM ap_invoices_interface WHERE NVL(status,'X') IN ('REJECTED','ERROR')
UNION ALL
SELECT 'RA_INTERFACE_LINES_ALL', COUNT(*) FROM ra_interface_lines_all WHERE interface_line_id IS NOT NULL AND NVL(interface_status,'X') = 'E'
UNION ALL
SELECT 'GL_INTERFACE status', COUNT(*) FROM gl_interface WHERE status <> 'NEW' AND status IS NOT NULL AND status NOT LIKE 'P%'
UNION ALL
SELECT 'PO_INTERFACE_ERRORS', COUNT(*) FROM po_interface_errors
UNION ALL
SELECT 'MTL_TRANSACTIONS_INTERFACE', COUNT(*) FROM mtl_transactions_interface WHERE error_code IS NOT NULL
UNION ALL
SELECT 'PA_TRANSACTION_INTERFACE', COUNT(*) FROM pa_transaction_interface_all WHERE transaction_status_code = 'R';

PROMPT
PROMPT === End of query: Error counts by module interface ===
PROMPT

-- End of file
