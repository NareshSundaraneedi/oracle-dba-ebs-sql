--------------------------------------------------------------------------------
-- File Name       : 02_cpu_suddenly_high.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : CPU suddenly high
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: host CPU 90%+ or DB CPU ≈ DB time. Initial: CPU_COUNT vs AAS on CPU, top SQL by CPU, runaway session. Evidence: OS top/perf, SESSTAT CPU, AWR if licensed. Causes: bad plan, parse storm, excessive PX, OS noisy neighbor. Fix: identify SQL_ID — tune or serialize PX. Do not add CPU as first move. Post-fix: DB CPU fraction and OS run queue normalized.
--
-- Production playbook.  identify SQL_ID — tune or serialize PX. Do not add CPU as first move.
-- Post-fix: DB CPU fraction and OS run queue normalized.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: CPU suddenly high — queries
--------------------------------------------------------------------------------
-- 1. What the query does
--    Playbook queries for this symptom.
-- 2. Important columns
--    See SELECT list / PROMPT for evidence to collect.
-- 3. How to interpret the output
--    Work Symptom → Initial checks → these SQL → Evidence → Root cause → Fix → Post-fix as in the file header DESCRIPTION.
-- 4. What indicates a problem
--    Matches the symptom in the file name.
-- 5. Recommended DBA action
--    See DESCRIPTION recommended fix. No destructive SQL is auto-run.
-- 6. Production cautions
--    Safe to query. Bounces, kills, and parameter changes are out of band.
-- 7. Required privileges
--    SELECT_CATALOG_ROLE
--------------------------------------------------------------------------------
SELECT value cpu_count FROM v$parameter WHERE name='cpu_count';
SELECT stat_name, ROUND(value/1e6,1) s FROM v$sys_time_model WHERE stat_name IN ('DB time','DB CPU');
SELECT s.sid, s.module, s.sql_id, ROUND(st.value/100,1) cpu_s
FROM gv$session s JOIN gv$sesstat st ON st.sid=s.sid AND st.inst_id=s.inst_id
JOIN gv$statname sn ON sn.statistic#=st.statistic# AND sn.inst_id=st.inst_id
WHERE sn.name='CPU used by this session' AND s.type='USER' ORDER BY st.value DESC FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT === End of query: CPU suddenly high — queries ===
PROMPT

-- End of file
