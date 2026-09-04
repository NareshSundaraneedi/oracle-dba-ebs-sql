--------------------------------------------------------------------------------
-- File Name       : 06_fnd_schemas.sql
-- Category        : 20_Oracle_EBS
-- Purpose         : FND / Oracle user mapping (FND_ORACLE_USERID)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Maps EBS application ids to Oracle schemas (GL -> GL, custom XX -> XXCUST).
--
-- Requires EBS R12.2 objects (APPLSYS/APPS). Will fail on a non-EBS database.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Oracle userids
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_ORACLE_USERID.
-- 2. Important columns
--    ORACLE_USERNAME, READ_ONLY_FLAG, ENABLED_FLAG.
-- 3. How to interpret the output
--    APPS is the runtime user. Product schemas should typically not be used for ad-hoc login.
-- 4. What indicates a problem
--    A product schema ENABLED unexpectedly or APPS missing.
-- 5. Recommended DBA action
--    Do not insert into FND_ORACLE_USERID. Use AD utilities.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT oracle_id, oracle_username, enabled_flag, read_only_flag, install_group_num
FROM fnd_oracle_userid
ORDER BY oracle_username;

PROMPT
PROMPT === End of query: Oracle userids ===
PROMPT

-- End of file
