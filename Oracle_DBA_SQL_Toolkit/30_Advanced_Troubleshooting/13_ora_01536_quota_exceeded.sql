--------------------------------------------------------------------------------
-- File Name       : 13_ora_01536_quota_exceeded.sql
-- Category        : 30_Advanced_Troubleshooting
-- Purpose         : ORA-01536 quota exceeded
-- Oracle Version  : 19c
-- EBS Version     : N/A
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Symptom: user cannot allocate in a tablespace. Initial: DBA_TS_QUOTAS for that user. Evidence: username + tablespace from the error. Causes: quota set for a human/batch schema. Fix: ALTER USER QUOTA — generated only after approval. EBS product users should not need ad-hoc quotas if they use the right TS. Post-fix: operation succeeds.
--
-- Production playbook.  ALTER USER QUOTA — generated only after approval. EBS product users should not need ad-hoc quotas if they use the right TS.
-- Post-fix: operation succeeds.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: ORA-01536 quota exceeded — queries
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
SELECT username, tablespace_name, bytes/1024/1024 used_mb, max_bytes/1024/1024 max_mb
FROM dba_ts_quotas WHERE max_bytes <> -1 ORDER BY username;
-- WARNING: Review carefully.
-- SELECT 'ALTER USER "'||username||'" QUOTA UNLIMITED ON '||tablespace_name||';' FROM dba_ts_quotas WHERE max_bytes<>-1;

PROMPT
PROMPT === End of query: ORA-01536 quota exceeded — queries ===
PROMPT

-- End of file
