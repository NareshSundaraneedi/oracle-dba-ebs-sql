--------------------------------------------------------------------------------
-- File Name       : 31_histogram_information.sql
-- Category        : 07_Performance_Tuning
-- Purpose         : Histograms on columns for a table (skew / bind peeking)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Histograms drive bind-sensitive plans. Too many FREQUENCY
-- histograms on EBS columns can cause unstable plans.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Column histograms for one table
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_TAB_COL_STATISTICS for &owner &table.
-- 2. Important columns
--    COLUMN_NAME, HISTOGRAM, NUM_DISTINCT, DENSITY, LAST_ANALYZED.
-- 3. How to interpret the output
--    HISTOGRAM NONE vs FREQUENCY vs HYBRID (12c+). HEIGHT BALANCED is legacy.
-- 4. What indicates a problem
--    A bind-peeked column with a FREQUENCY histogram and a popular value.
-- 5. Recommended DBA action
--    Consider locking stats or a SQL baseline rather than dropping all histograms.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on DBA_TAB_COL_STATISTICS, DBA_HISTOGRAMS
--------------------------------------------------------------------------------
DEFINE owner_p = GL
DEFINE table_p = GL_JE_LINES

SELECT
       column_name,
       num_distinct,
       density,
       histogram,
       num_buckets,
       last_analyzed,
       sample_size,
       notes
FROM   dba_tab_col_statistics
WHERE  owner = '&owner_p'
AND    table_name = '&table_p'
ORDER BY column_name;

SELECT column_name, endpoint_number, endpoint_value, endpoint_actual_value
FROM   dba_tab_histograms
WHERE  owner = '&owner_p'
AND    table_name = '&table_p'
AND    ROWNUM <= 200
ORDER BY column_name, endpoint_number;

PROMPT
PROMPT === End of query: Column histograms for one table ===
PROMPT

-- End of file
