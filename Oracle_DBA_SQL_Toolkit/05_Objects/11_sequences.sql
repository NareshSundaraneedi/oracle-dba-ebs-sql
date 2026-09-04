--------------------------------------------------------------------------------
-- File Name       : 11_sequences.sql
-- Category        : 05_Objects
-- Purpose         : Sequences near MAXVALUE or with odd cache settings
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Sequence exhaustion raises ORA-08004. RAC hot sequences with
-- NOCACHE cause SQ enqueue contention.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Sequence headroom and cache
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads DBA_SEQUENCES for remaining values and cache.
-- 2. Important columns
--    SEQUENCE_NAME, LAST_NUMBER, MAX_VALUE, CACHE_SIZE, ORDER_FLAG.
-- 3. How to interpret the output
--    CYCLE YES wraps. ORDER YES on RAC is a scalability tax.
-- 4. What indicates a problem
--    LAST_NUMBER within 10% of MAXVALUE. CACHE_SIZE 0 on a high-rate sequence.
-- 5. Recommended DBA action
--    ALTER SEQUENCE ... MAXVALUE / CACHE — generated only.
-- 6. Production cautions
--    WARNING: Changing sequences can create gaps or key collisions if mishandled. Generated only.
-- 7. Required privileges
--    SELECT on DBA_SEQUENCES
--------------------------------------------------------------------------------
SELECT
       sequence_owner,
       sequence_name,
       last_number,
       min_value,
       max_value,
       increment_by,
       cache_size,
       cycle_flag,
       order_flag,
       ROUND(last_number * 100 / NULLIF(max_value,0), 6) AS pct_used
FROM   dba_sequences
WHERE  sequence_owner NOT IN ('SYS','SYSTEM')
AND    (
         cache_size = 0
         OR last_number > max_value * 0.8
       )
ORDER BY pct_used DESC NULLS LAST;

PROMPT
PROMPT === End of query: Sequence headroom and cache ===
PROMPT

-- End of file
