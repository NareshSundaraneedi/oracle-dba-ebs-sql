--------------------------------------------------------------------------------
-- File Name       : 02_pending_requests.sql
-- Category        : 22_EBS_Concurrent_Requests
-- Purpose         : Pending requests by status (Normal/Standby/Scheduled/Inactive)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- PHASE P. Status Q standby, I scheduled, A waiting, R/C pending normal (check your decode).
--
-- EBS R12.2.x. Run as APPS (or a user with SELECT on APPLSYS/FND and APPS synonyms). Bind variables (:request_id, :hours, :username, :program_name) are provided as SQL*Plus DEFINE where useful.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Pending
--------------------------------------------------------------------------------
-- 1. What the query does
--    PHASE_CODE P.
-- 2. Important columns
--    STATUS_CODE, REQUEST_ID, REQUESTED_START_DATE, HOLD_FLAG.
-- 3. How to interpret the output
--    Future REQUESTED_START_DATE is scheduled, not stuck. HOLD_FLAG Y is held.
-- 4. What indicates a problem
--    Large Pending Normal queue and free manager slots.
-- 5. Recommended DBA action
--    21/15 manager not processing.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       r.request_id,
       r.status_code,
       r.hold_flag,
       r.requested_start_date,
       p.user_concurrent_program_name,
       u.user_name,
       ROUND((SYSDATE-r.request_date)*24*60,1) AS minutes_pending
FROM   fnd_concurrent_requests r
JOIN   fnd_concurrent_programs_vl p
       ON p.concurrent_program_id = r.concurrent_program_id
      AND p.application_id = r.program_application_id
JOIN   fnd_user u ON u.user_id = r.requested_by
WHERE  r.phase_code = 'P'
ORDER BY r.requested_start_date
FETCH FIRST 200 ROWS ONLY;

PROMPT
PROMPT === End of query: Pending ===
PROMPT

-- End of file
