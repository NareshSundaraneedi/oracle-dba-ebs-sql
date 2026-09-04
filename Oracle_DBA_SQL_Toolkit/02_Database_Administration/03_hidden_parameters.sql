--------------------------------------------------------------------------------
-- File Name       : 03_hidden_parameters.sql
-- Category        : 02_Database_Administration
-- Purpose         : List underscore parameters that have been explicitly set
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Underscore parameters must be Oracle Support approved. This script lists
-- only those present in the SPFILE/session, not the thousands of defaults.
--
-- Do not set underscore parameters without an SR or documented MOS note.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Specified hidden parameters
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$SPPARAMETER and X$KSPPI/X$KSPPCV for underscore parameters that are specified.
-- 2. Important columns
--    NAME, VALUE, ISDEFAULT, ISSES_MODIFIABLE.
-- 3. How to interpret the output
--    An underscore parameter that is not in the approved baseline is a risk during RU apply.
-- 4. What indicates a problem
--    Forgotten underscore leftovers after a one-off workaround (_allow_resetlogs_corruption, optimizer fixes).
-- 5. Recommended DBA action
--    Review each with Support. Remove obsolete ones during the next bounce window.
-- 6. Production cautions
--    Querying X$ requires SYS. Do not change underscore parameters from this script.
-- 7. Required privileges
--    SYSDBA or SELECT on X$KSPPI / X$KSPPCV
--
-- Requires SYS access. Oracle 19c.
--------------------------------------------------------------------------------
-- Preferred: what is actually specified in the SPFILE
SELECT sid, name, display_value
FROM   v$spparameter
WHERE  specified = 'TRUE'
AND    name LIKE '\_%' ESCAPE '\'
ORDER BY name, sid;

-- Full decoded list (SYS only). Comment out if you are not SYS.
-- SELECT
--        ksppinm  AS name,
--        ksppstvl AS value,
--        ksppstdf AS isdefault
-- FROM   x$ksppi a, x$ksppcv b
-- WHERE  a.indx = b.indx
-- AND    ksppinm LIKE '\_%' ESCAPE '\'
-- AND    ksppstdf = 'FALSE'
-- ORDER BY ksppinm;

PROMPT
PROMPT === End of query: Specified hidden parameters ===
PROMPT

-- End of file
