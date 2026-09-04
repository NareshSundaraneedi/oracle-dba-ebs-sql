--------------------------------------------------------------------------------
-- File Name       : 17_database_parameters.sql
-- Category        : 01_Basic
-- Purpose         : List non-default initialization parameters
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows parameters that differ from Oracle defaults. This is the set
-- you must document, compare across clones, and review after a PSU/RU.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Non-default parameters (spfile/source aware)
--------------------------------------------------------------------------------
-- 1. What the query does
--    Lists V$PARAMETER rows where ISDEFAULT = FALSE, including whether they are modified at session/system level.
-- 2. Important columns
--    NAME, VALUE, ISDEFAULT, ISMODIFIED, ISADJUSTED, ISBASIC, UPDATE_COMMENT.
-- 3. How to interpret the output
--    ISMODIFIED SYSTEM_MOD means a runtime ALTER SYSTEM that may not be in the SPFILE if SCOPE=MEMORY was used.
-- 4. What indicates a problem
--    Critical parameters (memory, processes, undo_retention, archive dest, cluster_interconnects) changed in MEMORY only — they will revert on bounce.
-- 5. Recommended DBA action
--    Compare with the approved parameter baseline. Persist intended changes with SCOPE=SPFILE or BOTH during a change window.
-- 6. Production cautions
--    Safe. Do not ALTER SYSTEM from this script. Underscore parameters are in 02_Database_Administration/03_hidden_parameters.sql.
-- 7. Required privileges
--    SELECT on V_$PARAMETER
--------------------------------------------------------------------------------
SELECT
       name,
       display_value,
       isdefault,
       issys_modifiable,
       ismodified,
       isadjusted,
       isbasic,
       description
FROM   v$parameter
WHERE  isdefault = 'FALSE'
ORDER BY name;

PROMPT
PROMPT === End of query: Non-default parameters (spfile/source aware) ===
PROMPT

-- End of file
