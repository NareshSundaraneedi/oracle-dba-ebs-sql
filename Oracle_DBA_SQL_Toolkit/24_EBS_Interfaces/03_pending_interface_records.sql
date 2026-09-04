--------------------------------------------------------------------------------
-- File Name       : 03_pending_interface_records.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Unprocessed / NEW / PENDING interface rows
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Backlog waiting for the import program.
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
-- QUERY 1: Pending counts
--------------------------------------------------------------------------------
-- 1. What the query does
--    NEW/PENDING style statuses.
-- 2. Important columns
--    SOURCE, PENDING.
-- 3. How to interpret the output
--    A controlled backlog before a scheduled import is OK. Unbounded growth is not.
-- 4. What indicates a problem
--    Pending since > 1 day on a near-real-time interface.
-- 5. Recommended DBA action
--    Check the import concurrent program (22) and manager.
-- 6. Production cautions
--    Safe-ish; avoid peak COUNT(*) on huge GL_INTERFACE — consider date filter in module scripts.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT 'AP invoices NEW' src, COUNT(*) cnt FROM ap_invoices_interface WHERE NVL(status,'NEW') IN ('NEW','PENDING')
UNION ALL
SELECT 'GL_INTERFACE NEW', COUNT(*) FROM gl_interface WHERE status = 'NEW'
UNION ALL
SELECT 'MTL_TXN PROCESS_FLAG', COUNT(*) FROM mtl_transactions_interface WHERE process_flag = '1'
UNION ALL
SELECT 'OE_HEADERS_IFACE', COUNT(*) FROM oe_headers_iface_all WHERE NVL(error_flag,'N') = 'N' AND NVL(request_id,0) = 0
UNION ALL
SELECT 'PA_TXN PENDING', COUNT(*) FROM pa_transaction_interface_all WHERE transaction_status_code = 'P';

PROMPT
PROMPT === End of query: Pending counts ===
PROMPT

-- End of file
