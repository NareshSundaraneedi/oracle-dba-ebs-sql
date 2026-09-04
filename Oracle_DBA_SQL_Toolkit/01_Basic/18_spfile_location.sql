--------------------------------------------------------------------------------
-- File Name       : 18_spfile_location.sql
-- Category        : 01_Basic
-- Purpose         : Locate the SPFILE the instance is using
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Confirms whether the instance started with an SPFILE (preferred) or
-- a PFILE, and where that SPFILE lives (file system or ASM).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: SPFILE path and pfile fallback
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads the SPFILE parameter and V$SPPARAMETER for the source.
-- 2. Important columns
--    SPFILE path, SID, NAME, VALUE, ISSPECIFIED.
-- 3. How to interpret the output
--    Empty SPFILE value means the instance started from a PFILE. ASM paths start with +.
-- 4. What indicates a problem
--    Started from a PFILE after an emergency bounce — subsequent ALTER SYSTEM SCOPE=SPFILE will fail or write to an unexpected file.
-- 5. Recommended DBA action
--    If SPFILE is missing, recreate it from the approved pfile during a change window: CREATE SPFILE FROM PFILE.
-- 6. Production cautions
--    Safe. Creating an SPFILE is a change — not executed here.
-- 7. Required privileges
--    SELECT on V_$PARAMETER, V_$SPPARAMETER
--------------------------------------------------------------------------------
SELECT name, value
FROM   v$parameter
WHERE  name = 'spfile';

SELECT
       sid,
       name,
       display_value,
       ordinal,
       specified
FROM   v$spparameter
WHERE  specified = 'TRUE'
ORDER BY name, sid, ordinal;

PROMPT
PROMPT === End of query: SPFILE path and pfile fallback ===
PROMPT

-- End of file
