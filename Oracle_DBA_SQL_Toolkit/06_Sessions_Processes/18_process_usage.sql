--------------------------------------------------------------------------------
-- File Name       : 18_process_usage.sql
-- Category        : 06_Sessions_Processes
-- Purpose         : OS process list as seen by Oracle (V$PROCESS)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Maps SID to SPID for OS-level investigation (pstack, top).
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Process to session map
--------------------------------------------------------------------------------
-- 1. What the query does
--    Joins GV$PROCESS to GV$SESSION.
-- 2. Important columns
--    SPID, SID, PROGRAM, PGA_ALLOC_MB.
-- 3. How to interpret the output
--    SPID is the OS pid on that instance's host.
-- 4. What indicates a problem
--    Orphan processes (process without session) after a kill -9 — rare; more often extra parallel slaves.
-- 5. Recommended DBA action
--    Use SPID on the correct RAC node. Do not kill -9 Oracle processes.
-- 6. Production cautions
--    Safe to query. Never kill -9 smon/pmon/lmd.
-- 7. Required privileges
--    SELECT on GV_$PROCESS, GV_$SESSION
--------------------------------------------------------------------------------
SELECT
       p.inst_id,
       p.spid,
       p.pid,
       s.sid,
       s.serial#,
       s.username,
       s.program,
       p.program AS process_program,
       ROUND(p.pga_alloc_mem/1024/1024,1) AS pga_alloc_mb
FROM   gv$process p
LEFT JOIN gv$session s ON s.inst_id = p.inst_id AND s.paddr = p.addr
ORDER BY p.inst_id, p.spid;

PROMPT
PROMPT === End of query: Process to session map ===
PROMPT

-- End of file
