--------------------------------------------------------------------------------
-- File Name       : 15_pa_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Projects transaction import (PA_TRANSACTION_INTERFACE_ALL)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- TRANSACTION_STATUS_CODE P=pending A=accepted R=rejected. PRC: Transaction Import.
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
-- QUERY 1: PA transaction interface
--------------------------------------------------------------------------------
-- 1. What the query does
--    Status by transaction_source.
-- 2. Important columns
--    STATUS, SOURCE, CNT.
-- 3. How to interpret the output
--    Rejected need REJECTED_REASON.
-- 4. What indicates a problem
--    Rejected after a resource / expenditure type change.
-- 5. Recommended DBA action
--    Fix and re-import. Do not UPDATE status to P without fixing reason.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT transaction_status_code, transaction_source, COUNT(*) cnt
FROM pa_transaction_interface_all
GROUP BY transaction_status_code, transaction_source
ORDER BY cnt DESC;

SELECT txn_interface_id, transaction_status_code, transaction_source,
       rejected_reason, expenditure_ending_date
FROM pa_transaction_interface_all
WHERE transaction_status_code = 'R'
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: PA transaction interface ===
PROMPT

-- End of file
