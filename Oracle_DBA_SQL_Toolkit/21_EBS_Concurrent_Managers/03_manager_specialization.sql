--------------------------------------------------------------------------------
-- File Name       : 03_manager_specialization.sql
-- Category        : 21_EBS_Concurrent_Managers
-- Purpose         : Specialization rules (include/exclude programs)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Why a request sits Pending/Standby: no manager includes that program, or a specialization excludes it.
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
-- QUERY 1: Queue content / specialization
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_CONCURRENT_QUEUE_CONTENT joined to programs.
-- 2. Important columns
--    QUEUE, INCLUDE_FLAG, TYPE_CODE, PROGRAM_NAME.
-- 3. How to interpret the output
--    INCLUDE_FLAG I=include E=exclude. TYPE_CODE P=program C=complex R=request type.
-- 4. What indicates a problem
--    A custom program not included in any running manager other than Standard, and Standard is flooded.
-- 5. Recommended DBA action
--    Add specialization via Define Manager form. Not SQL inserts.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT
       q.user_concurrent_queue_name,
       c.include_flag,
       c.type_code,
       c.type_application_id,
       fcp.concurrent_program_name,
       fcp.user_concurrent_program_name
FROM   fnd_concurrent_queue_content c
JOIN   fnd_concurrent_queues_vl q
       ON q.concurrent_queue_id = c.concurrent_queue_id
      AND q.application_id = c.queue_application_id
LEFT JOIN fnd_concurrent_programs_vl fcp
       ON fcp.concurrent_program_id = c.type_id
      AND c.type_code = 'P'
ORDER BY q.user_concurrent_queue_name, c.include_flag, fcp.concurrent_program_name;

PROMPT
PROMPT === End of query: Queue content / specialization ===
PROMPT

-- End of file
