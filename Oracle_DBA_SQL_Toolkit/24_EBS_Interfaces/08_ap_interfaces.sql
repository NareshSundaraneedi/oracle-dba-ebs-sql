--------------------------------------------------------------------------------
-- File Name       : 08_ap_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Payables Open Interface (AP_INVOICES_INTERFACE)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- STATUS NEW/REJECTED, reject_lookup_code. Process with Payables Open Interface Import (APXIIMPT).
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
-- QUERY 1: AP interface backlog and rejects
--------------------------------------------------------------------------------
-- 1. What the query does
--    Counts and sample rejects.
-- 2. Important columns
--    STATUS, SOURCE, CNT, REJECT_LOOKUP_CODE.
-- 3. How to interpret the output
--    SOURCE tells you the feeder (iSupplier, custom XX, EDI).
-- 4. What indicates a problem
--    REJECTED with DUPLICATE INVOICE or invalid vendor.
-- 5. Recommended DBA action
--    Fix feeder data. Reprocess via Import — do not UPDATE invoice_id.
-- 6. Production cautions
--    Safe. Large sites: add creation_date filter.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT NVL(status,'NEW') status, source, COUNT(*) cnt
FROM ap_invoices_interface
GROUP BY NVL(status,'NEW'), source
ORDER BY cnt DESC;

SELECT invoice_num, source, status, reject_lookup_code, vendor_id, org_id, creation_date
FROM ap_invoices_interface
WHERE NVL(status,'NEW') IN ('REJECTED','ERROR')
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: AP interface backlog and rejects ===
PROMPT

-- End of file
