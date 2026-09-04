--------------------------------------------------------------------------------
-- File Name       : 02_find_oracle_session.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Step 2 — find the Oracle session for a request
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Map REQUEST_ID to INST_ID, SID, SERIAL#, SPID, MACHINE, MODULE. Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.
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
-- QUERY 1: Step 2 — find the Oracle session for a request
--------------------------------------------------------------------------------
-- 1. What the query does
--    Map REQUEST_ID to INST_ID, SID, SERIAL#, SPID, MACHINE, MODULE.
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
DEFINE request_id = 0
SELECT r.request_id, r.oracle_session_id,
       s.inst_id, s.sid, s.serial#, s.status, s.event, s.sql_id, s.module, s.machine, s.program,
       p.spid, ROUND(p.pga_alloc_mem/1024/1024,1) pga_mb
FROM fnd_concurrent_requests r
LEFT JOIN gv$session s ON s.sid = r.oracle_session_id AND s.username='APPS'
LEFT JOIN gv$process p ON p.inst_id=s.inst_id AND p.addr=s.paddr
WHERE r.request_id = &request_id;
-- Fallback if oracle_session_id is null:
SELECT s.inst_id, s.sid, s.serial#, s.sql_id, s.event, s.module, s.action
FROM gv$session s
WHERE s.username='APPS'
AND (s.module LIKE '%'||(SELECT concurrent_program_name FROM fnd_concurrent_programs_vl p
      JOIN fnd_concurrent_requests r ON r.concurrent_program_id=p.concurrent_program_id
      WHERE r.request_id=&request_id AND ROWNUM=1)||'%'
     OR s.action LIKE '%'||TO_CHAR(&request_id)||'%');

PROMPT
PROMPT === End of query: Step 2 — find the Oracle session for a request ===
PROMPT

-- End of file
