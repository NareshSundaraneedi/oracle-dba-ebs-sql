--------------------------------------------------------------------------------
-- File Name       : 17_generate_disconnect_session.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : Generate ALTER SYSTEM DISCONNECT SESSION ... POST_TRANSACTION commands
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- DISCONNECT SESSION POST_TRANSACTION is gentler than KILL: it lets
-- the current transaction finish then drops the session. Use for inactive
-- Forms sessions holding locks when you can wait for a commit.
--
-- WARNING: Generated only. IMMEDIATE is more aggressive than POST_TRANSACTION.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Generate disconnect commands
--------------------------------------------------------------------------------
-- 1. What the query does
--    Builds DISCONNECT SESSION commands.
-- 2. Important columns
--    DISCONNECT_CMD, SID, STATUS.
-- 3. How to interpret the output
--    POST_TRANSACTION waits for commit/rollback. IMMEDIATE is similar to kill.
-- 4. What indicates a problem
--    N/A — helper.
-- 5. Recommended DBA action
--    Prefer POST_TRANSACTION for inactive lock holders if the user might commit.
-- 6. Production cautions
--    WARNING: Destructive. Generated only. Safety predicate 1=0.
-- 7. Required privileges
--    SELECT on GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       'ALTER SYSTEM DISCONNECT SESSION ''' || sid || ',' || serial# || ',@' || inst_id || ''' POST_TRANSACTION;' AS disconnect_cmd,
       inst_id,
       sid,
       serial#,
       username,
       module,
       status,
       last_call_et
FROM   gv$session
WHERE  1 = 0  -- safety: edit before use
;

PROMPT
PROMPT === End of query: Generate disconnect commands ===
PROMPT

-- End of file
