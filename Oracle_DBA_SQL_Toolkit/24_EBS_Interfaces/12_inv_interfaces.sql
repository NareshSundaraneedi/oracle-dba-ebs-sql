--------------------------------------------------------------------------------
-- File Name       : 12_inv_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Inventory transaction and item interfaces
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- MTL_TRANSACTIONS_INTERFACE process_flag 1=pending 3=error. INCTIM processes it.
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
-- QUERY 1: MTL transactions interface
--------------------------------------------------------------------------------
-- 1. What the query does
--    Process flag / error code histogram.
-- 2. Important columns
--    PROCESS_FLAG, ERROR_CODE, CNT.
-- 3. How to interpret the output
--    Flag 1 backlog = INCTIM not running or locked. Flag 3 = data/period/qty errors.
-- 4. What indicates a problem
--    Error 40 / period not open — functional period close issue.
-- 5. Recommended DBA action
--    Inventory period / account aliases. Do not set process_flag back to 1 without fixing ERROR_EXPLANATION.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT process_flag, error_code, COUNT(*) cnt
FROM mtl_transactions_interface
GROUP BY process_flag, error_code
ORDER BY cnt DESC;

SELECT transaction_interface_id, process_flag, error_code, error_explanation,
       organization_id, transaction_type_id, creation_date
FROM mtl_transactions_interface
WHERE process_flag = '3' OR error_code IS NOT NULL
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: MTL transactions interface ===
PROMPT

-- End of file
