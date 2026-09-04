--------------------------------------------------------------------------------
-- File Name       : 04_audit_trail_location.sql
-- Category        : 19_Auditing_Security
-- Purpose         : Where audit records live and AUDSYS storage
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Unified audit tables live in AUDSYS (often SYSAUX). Growth fills SYSAUX if not purged.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: AUDSYS segments and audit table
--------------------------------------------------------------------------------
-- 1. What the query does
--    DBA_SEGMENTS for AUDSYS + DBMS_AUDIT_MGMT trail properties if accessible.
-- 2. Important columns
--    SEGMENT_NAME, SIZE_MB.
-- 3. How to interpret the output
--    AUD$UNIFIED is the typical unified table (internal name may vary by release).
-- 4. What indicates a problem
--    AUDSYS tens of GB and growing daily.
-- 5. Recommended DBA action
--    See 06/07 for growth and purge. Do not TRUNCATE AUDSYS.
-- 6. Production cautions
--    Safe. Do not move tablespaces without MOS guidance.
-- 7. Required privileges
--    SELECT on DBA_SEGMENTS, DBA_USERS
--------------------------------------------------------------------------------
SELECT username, default_tablespace FROM dba_users WHERE username = 'AUDSYS';
SELECT segment_name, segment_type, tablespace_name, ROUND(bytes/1024/1024,1) mb
FROM dba_segments WHERE owner = 'AUDSYS'
ORDER BY bytes DESC;

PROMPT
PROMPT === End of query: AUDSYS segments and audit table ===
PROMPT

-- End of file
