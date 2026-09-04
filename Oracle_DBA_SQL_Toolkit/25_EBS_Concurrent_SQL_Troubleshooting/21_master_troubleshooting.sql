--------------------------------------------------------------------------------
-- File Name       : 21_master_troubleshooting.sql
-- Category        : 25_EBS_Concurrent_SQL_Troubleshooting
-- Purpose         : Master correlation: Request → Session → SQL → Plan → Wait → Blocker → Resources → Action
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Run this first during an EBS long-request incident. It correlates the chain in one spool.
-- Then use scripts 01-20 to drill the finding.
--
-- Chain:
--   Concurrent Request
--        ↓
--   Oracle Session (SID/SERIAL@INST)
--        ↓
--   SQL_ID / SQL text
--        ↓
--   Execution plan hash
--        ↓
--   Wait event / blocking session
--        ↓
--   CPU / I/O / TEMP / PGA
--        ↓
--   Root cause hypothesis
--        ↓
--   Recommended action (tune / stats / lock / manager / cancel)
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
-- QUERY 1: Master correlation for &request_id
--------------------------------------------------------------------------------
-- 1. What the query does
--    Single script joining FND_CONCURRENT_REQUESTS, GV$SESSION, GV$SQL, GV$PROCESS, temp, locks.
-- 2. Important columns
--    REQUEST_ID, SID, SQL_ID, EVENT, BLOCKER, PGA_MB, TEMP_MB, ELA_S.
-- 3. How to interpret the output
--    Read top to bottom. If EVENT is enq:, go to locks. If TEMP_MB high, spill. If SQL_ID null, apps-tier program.
-- 4. What indicates a problem
--    Hours_running high AND blocker present — do not tune SQL, clear the lock.
-- 5. Recommended DBA action
--    Follow the recommended_action CASE. Cancel request only with functional approval (not done here).
-- 6. Production cautions
--    Safe. Does not kill or cancel. Diagnostics Pack not required.
-- 7. Required privileges
--    APPS + SELECT on GV$ views
--------------------------------------------------------------------------------
DEFINE request_id = 0

COLUMN recommended_action FORMAT A80

SELECT
       r.request_id,
       p.user_concurrent_program_name AS program,
       u.user_name,
       ROUND((SYSDATE-r.actual_start_date)*24*60,1) AS minutes_running,
       s.inst_id, s.sid, s.serial#,
       s.sql_id,
       s.event AS wait_event,
       s.wait_class,
       s.blocking_session,
       s.blocking_instance,
       ROUND(pr.pga_alloc_mem/1024/1024,1) AS pga_mb,
       (SELECT ROUND(SUM(t.blocks)*8/1024,1) FROM gv$tempseg_usage t
         WHERE t.inst_id=s.inst_id AND t.sid=s.sid) AS temp_mb,
       q.plan_hash_value,
       ROUND(q.elapsed_time/1e6,1) AS sql_ela_s,
       CASE
         WHEN s.sid IS NULL THEN 'No DB session — check request log / host executable'
         WHEN s.blocking_session IS NOT NULL THEN 'LOCK: clear root blocker (folder 10). Do not tune yet'
         WHEN s.event LIKE 'enq:%' THEN 'LOCK/enqueue — folder 10 and 25/07'
         WHEN NVL((SELECT SUM(t.blocks) FROM gv$tempseg_usage t WHERE t.inst_id=s.inst_id AND t.sid=s.sid),0) > 128000
              THEN 'TEMP spill — 14_TEMP + tune hash/sort (25/11)'
         WHEN s.event LIKE 'db file scattered%' OR s.event LIKE 'direct path read%'
              THEN 'FTS/I/O — plan + stats (25/05, 17, 18)'
         WHEN s.event LIKE 'log file sync%' THEN 'Commit wait — redo/commit rate, not the SQL shape'
         ELSE 'Review plan/binds/stats (25/05, 15, 16, 17) then 08_SQL_Tuning'
       END AS recommended_action
FROM   fnd_concurrent_requests r
JOIN   fnd_concurrent_programs_vl p
       ON p.concurrent_program_id = r.concurrent_program_id
      AND p.application_id = r.program_application_id
JOIN   fnd_user u ON u.user_id = r.requested_by
LEFT JOIN gv$session s ON s.sid = r.oracle_session_id AND s.username = 'APPS'
LEFT JOIN gv$process pr ON pr.inst_id = s.inst_id AND pr.addr = s.paddr
LEFT JOIN gv$sql q ON q.inst_id = s.inst_id AND q.sql_id = s.sql_id AND q.child_number = s.sql_child_number
WHERE  r.request_id = &request_id;

PROMPT Next: run 04 (SQL text), 05 (plan), 06-20 as indicated by recommended_action.

PROMPT
PROMPT === End of query: Master correlation for &request_id ===
PROMPT

-- End of file
