--------------------------------------------------------------------------------
-- File Name       : 14_transaction_manager.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Transaction managers (PO/INV/etc. AQ / TM)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Transaction Managers process immediate/synchronous requests (PO Document Approval style). They use TIME-BASED or AQ. If TM is down, forms hang on 'transaction manager'.
--
-- EBS R12.2.x. Run as APPS (or a user with SELECT on APPLSYS/FND and APPS synonyms). Bind variables (:request_id, :hours, :username, :program_name) are provided as SQL*Plus DEFINE where useful.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Transaction managers
--------------------------------------------------------------------------------
-- 1. What the query does
--    Queues with manager_type / user name like Transaction / PONEM / INV.
-- 2. Important columns
--    QUEUE, TARGET, RUNNING, MANAGER_TYPE.
-- 3. How to interpret the output
--    MANAGER_TYPE 1=concurrent, 2=transaction (verify on your site — also look at user name).
-- 4. What indicates a problem
--    PO Transaction Manager running_processes=0 — document approval hangs.
-- 5. Recommended DBA action
--    Start the product TM. Check AQ / wf_control. See MOS for TM troubleshooting.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT concurrent_queue_name, user_concurrent_queue_name, manager_type,
       target_processes, running_processes, enabled_flag, target_node
FROM fnd_concurrent_queues_vl
WHERE UPPER(user_concurrent_queue_name) LIKE '%TRANSACTION%'
   OR concurrent_queue_name LIKE '%TM%'
   OR manager_type = 2
ORDER BY user_concurrent_queue_name;

PROMPT
PROMPT === End of query: Transaction managers ===
PROMPT

-- End of file
