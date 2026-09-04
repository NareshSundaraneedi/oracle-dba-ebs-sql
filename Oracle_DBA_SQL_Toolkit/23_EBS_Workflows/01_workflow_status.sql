--------------------------------------------------------------------------------
-- File Name       : 01_workflow_status.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : Open workflow items by item type and status
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- WF_ITEMS is the header. END_DATE null means still open. Huge open counts after a stuck WF background engine.
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
-- QUERY 1: Open items by type
--------------------------------------------------------------------------------
-- 1. What the query does
--    WF_ITEMS where end_date is null, grouped.
-- 2. Important columns
--    ITEM_TYPE, ROOT_COUNT, OLDEST.
-- 3. How to interpret the output
--    OEOH, REQAPPRV, POAPPRV commonly have open items. Compare to a known baseline.
-- 4. What indicates a problem
--    Open count growing every day — purge not running or engine stuck.
-- 5. Recommended DBA action
--    Check Workflow Background Process requests (22) and 06/07 listeners.
-- 6. Production cautions
--    Safe. WF_ITEMS can be large — no full scan of history.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT item_type, COUNT(*) open_items,
       MIN(begin_date) oldest, MAX(begin_date) newest
FROM wf_items
WHERE end_date IS NULL
GROUP BY item_type
ORDER BY open_items DESC;

PROMPT
PROMPT === End of query: Open items by type ===
PROMPT

-- End of file
