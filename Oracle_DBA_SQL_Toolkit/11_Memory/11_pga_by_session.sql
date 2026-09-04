--------------------------------------------------------------------------------
-- File Name       : 11_pga_by_session.sql
-- Category        : 11_Memory
-- Purpose         : PGA by session (memory folder copy of session view)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Same join as 06/12. Kept here so memory investigations do not jump folders. Use 06/12 when the ticket is 'who'; use this when the ticket is 'PGA'.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Session PGA
--------------------------------------------------------------------------------
-- 1. What the query does
--    GV$PROCESS joined to sessions.
-- 2. Important columns
--    PGA_USED_MB, SQL_ID.
-- 3. How to interpret the output
--    A few hundred MB can be normal for a hash join. Multi-GB is a suspect.
-- 4. What indicates a problem
--    One session near pga_aggregate_limit.
-- 5. Recommended DBA action
--    Identify SQL. Kill only as last resort (generate in 06).
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    SELECT on GV_$SESSION, GV_$PROCESS
--------------------------------------------------------------------------------
SELECT s.inst_id, s.sid, s.serial#, s.username, s.module, s.sql_id,
       ROUND(p.pga_used_mem/1024/1024,1) pga_used_mb,
       ROUND(p.pga_alloc_mem/1024/1024,1) pga_alloc_mb
FROM gv$session s JOIN gv$process p ON p.inst_id=s.inst_id AND p.addr=s.paddr
WHERE s.type='USER' ORDER BY p.pga_alloc_mem DESC FETCH FIRST 40 ROWS ONLY;

PROMPT
PROMPT === End of query: Session PGA ===
PROMPT

-- End of file
