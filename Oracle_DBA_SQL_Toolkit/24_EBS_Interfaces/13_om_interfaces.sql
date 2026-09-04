--------------------------------------------------------------------------------
-- File Name       : 13_om_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Order Import (OE_HEADERS_IFACE_ALL / OE_LINES_IFACE_ALL)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- OEOIMP. ERROR_FLAG Y means failed. REQUEST_ID ties to the import run.
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
-- QUERY 1: OM interface
--------------------------------------------------------------------------------
-- 1. What the query does
--    Header error flags and sample messages.
-- 2. Important columns
--    ERROR_FLAG, ORDER_SOURCE, CNT.
-- 3. How to interpret the output
--    Lines can fail independently — always check both header and line iface.
-- 4. What indicates a problem
--    ERROR_FLAG Y after a pricing/item setup change.
-- 5. Recommended DBA action
--    Order Import + interface errors form. Do not delete customer orders from iface without functional OK.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT NVL(error_flag,'N') error_flag, order_source_id, COUNT(*) cnt
FROM oe_headers_iface_all
GROUP BY NVL(error_flag,'N'), order_source_id;

SELECT orig_sys_document_ref, error_flag, request_id, org_id, creation_date
FROM oe_headers_iface_all
WHERE error_flag = 'Y'
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: OM interface ===
PROMPT

-- End of file
