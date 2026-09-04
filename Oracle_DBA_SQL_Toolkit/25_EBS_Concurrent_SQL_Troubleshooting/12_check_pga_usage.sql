--------------------------------------------------------------------------------
-- File Name       : 12_check_pga_usage.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 12 — PGA for the session
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Process PGA used/alloc. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
--
-- EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Step 12 — PGA for the session
--------------------------------------------------------------------------------
-- 1. What the query does
--    Process PGA used/alloc.
-- 2. Important columns
--    See SELECT list.
-- 3. How to interpret the output
--    Capture the output into the incident ticket before changing anything.
-- 4. What indicates a problem
--    Missing session or SQL_ID means the program is not in a DB call — check the request log.
-- 5. Recommended DBA action
--    Continue the next numbered script. Do not skip to kill.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS + SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
DEFINE sid = 0
DEFINE inst = 1
SELECT s.sid, ROUND(p.pga_used_mem/1024/1024,1) used_mb,
       ROUND(p.pga_alloc_mem/1024/1024,1) alloc_mb, p.spid
FROM gv$session s JOIN gv$process p ON p.inst_id=s.inst_id AND p.addr=s.paddr
WHERE s.inst_id=&inst AND s.sid=&sid;

PROMPT
PROMPT === End of query: Step 12 — PGA for the session ===
PROMPT

-- End of file
