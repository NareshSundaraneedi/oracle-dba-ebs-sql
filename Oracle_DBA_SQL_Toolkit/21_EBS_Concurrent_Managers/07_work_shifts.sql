--------------------------------------------------------------------------------
-- File Name       : 07_work_shifts.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Work shifts assigned to managers
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_CONCURRENT_QUEUE_SIZE maps queues to work shifts (FND_WORK_SHIFTS).
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
-- QUERY 1: Shifts
--------------------------------------------------------------------------------
-- 1. What the query does
--    Queue to shift mapping with from/to times.
-- 2. Important columns
--    QUEUE, SHIFT, FROM, TO, TARGET_PROCESSES.
-- 3. How to interpret the output
--    A day shift 08:00-18:00 with 10 processes and night 0 explains overnight pending backlog.
-- 4. What indicates a problem
--    No current shift — TARGET becomes 0.
-- 5. Recommended DBA action
--    Define a 24x7 shift for Standard/ICM on production.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       q.user_concurrent_queue_name,
       ws.shift_name,
       qsz.min_processes,
       qsz.max_processes,
       qsz.sleep_seconds,
       ws.from_time,
       ws.to_time
FROM   fnd_concurrent_queue_size qsz
JOIN   fnd_concurrent_queues_vl q
       ON q.concurrent_queue_id = qsz.concurrent_queue_id
      AND q.application_id = qsz.queue_application_id
JOIN   fnd_work_shifts_vl ws
       ON ws.work_shift_id = qsz.work_shift_id
ORDER BY q.user_concurrent_queue_name, ws.from_time;

PROMPT
PROMPT === End of query: Shifts ===
PROMPT

-- End of file
