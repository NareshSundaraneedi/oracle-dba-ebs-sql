--------------------------------------------------------------------------------
-- File Name       : 05_sql_profiles.sql
-- Category        : 08_SQL_Tuning
-- Purpose         : List existing SQL profiles
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows profiles already in the database so you do not create
-- duplicates and so you can see what was accepted after an incident.
--
-- LICENSING: Creating SQL profiles is Tuning Pack. Listing DBA_SQL_PROFILES is a dictionary query.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SQL profiles
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_SQL_PROFILES.
-- 2. Important columns
--    NAME, STATUS, SQL_TEXT, CREATED.
-- 3. How to interpret the output
--    ENABLED profiles influence matching statements. CATEGORY DEFAULT applies to all sessions unless altered.
-- 4. What indicates a problem
--    A leftover profile from a test forcing a bad plan.
-- 5. Recommended DBA action
--    DISABLE is a change. Generated only.
-- 6. Production cautions
--    WARNING: ALTER/DROP SQL PROFILE generated only.
-- 7. Required privileges
--    SELECT on DBA_SQL_PROFILES
--------------------------------------------------------------------------------
SELECT
       name,
       category,
       status,
       created,
       last_modified,
       SUBSTR(sql_text,1,200) AS sql_text
FROM   dba_sql_profiles
ORDER BY created DESC;

-- WARNING: Review carefully.
-- SELECT 'EXEC DBMS_SQLTUNE.ALTER_SQL_PROFILE('''||name||''',''STATUS'',''DISABLED'');' FROM dba_sql_profiles WHERE status = 'ENABLED';

PROMPT
PROMPT === End of query: SQL profiles ===
PROMPT

-- End of file
