--------------------------------------------------------------------------------
-- File Name       : 09_ar_interfaces.sql
-- Category        : 24_EBS_Interfaces
-- Purpose         : Autoinvoice (RA_INTERFACE_LINES_ALL)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- INTERFACE_STATUS / BATCH. Errors also in RA_INTERFACE_ERRORS_ALL if present.
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
-- QUERY 1: AR Autoinvoice backlog
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lines by request_id / interface_status.
-- 2. Important columns
--    INTERFACE_STATUS, BATCH, CNT.
-- 3. How to interpret the output
--    Lines with no request_id are waiting for Autoinvoice.
-- 4. What indicates a problem
--    Lines stuck after a failed RAXMTR — may need to clear request_id per MOS, not casually.
-- 5. Recommended DBA action
--    Autoinvoice Import Program. Review RA_INTERFACE_ERRORS_ALL.
-- 6. Production cautions
--    Do not DELETE interface lines without AR functional sign-off.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT NVL(interface_status,'NEW') interface_status, COUNT(*) cnt,
       COUNT(DISTINCT request_id) requests
FROM ra_interface_lines_all
GROUP BY NVL(interface_status,'NEW');

SELECT * FROM ra_interface_errors_all
ORDER BY interface_line_id DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT
PROMPT === End of query: AR Autoinvoice backlog ===
PROMPT

-- End of file
