--------------------------------------------------------------------------------
-- File Name       : 06_oracle_home.sql
-- Category        : 01_Basic
-- Purpose         : Locate ORACLE_HOME and ORACLE_BASE used by the instance
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows the Oracle home the running instance was started from. Essential
-- when multiple homes exist (for example 19c gold image vs old home).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Oracle home from V$PARAMETER and SYS_CONTEXT
--------------------------------------------------------------------------------
-- 1. What the query does
--    Derives ORACLE_HOME from the SPFILE/background dump path and session environment.
-- 2. Important columns
--    ORACLE_HOME (derived), DIAGNOSTIC_DEST, SPFILE.
-- 3. How to interpret the output
--    The running instance home may differ from the shell ORACLE_HOME of your SQL*Plus session.
-- 4. What indicates a problem
--    Patching or opatch lsinventory run against a different home than the running instance.
-- 5. Recommended DBA action
--    Use the home reported here for opatch, relink, and listener configuration.
-- 6. Production cautions
--    V$PARAMETER.VALUE for diagnostic_dest is ORACLE_BASE/diag in 11g+ ADR.
-- 7. Required privileges
--    SELECT on V_$PARAMETER
--------------------------------------------------------------------------------
SELECT
       SYS_CONTEXT('USERENV','ORACLE_HOME') AS oracle_home,
       (SELECT value FROM v$parameter WHERE name = 'diagnostic_dest') AS diagnostic_dest,
       (SELECT value FROM v$parameter WHERE name = 'spfile')          AS spfile,
       (SELECT value FROM v$parameter WHERE name = 'background_dump_dest') AS background_dump_dest
FROM   dual;

PROMPT
PROMPT === End of query: Oracle home from V$PARAMETER and SYS_CONTEXT ===
PROMPT

-- End of file
