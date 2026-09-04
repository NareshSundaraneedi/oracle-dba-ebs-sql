--------------------------------------------------------------------------------
-- File Name       : 14_hr_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : HR / Payroll API transactions and common staging
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- HR_API_TRANSACTIONS holds SSHR / API transactions. Status and transaction_ref help find stuck approvals.
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
-- QUERY 1: HR API transactions
--------------------------------------------------------------------------------
-- 1. What the query does
--    HR_API_TRANSACTIONS by status.
-- 2. Important columns
--    STATUS, CNT, OLDEST.
-- 3. How to interpret the output
--    Status values are product-specific (Y/C/E etc.). Confirm against your HR patch level.
-- 4. What indicates a problem
--    Stuck transactions after Workflow mailer outage.
-- 5. Recommended DBA action
--    HR Workflow + API transaction monitor. Do not delete HR_API_TRANSACTIONS.
-- 6. Production cautions
--    PII — handle output as confidential.
-- 7. Required privileges
--    APPS (HR security may hide rows)
--------------------------------------------------------------------------------
SELECT status, COUNT(*) cnt, MIN(creation_date) oldest, MAX(creation_date) newest
FROM hr_api_transactions
GROUP BY status
ORDER BY cnt DESC;

SELECT transaction_id, status, transaction_ref, creation_date, selected_person_id
FROM hr_api_transactions
WHERE status NOT IN ('Y','C')
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: HR API transactions ===
PROMPT

-- End of file
