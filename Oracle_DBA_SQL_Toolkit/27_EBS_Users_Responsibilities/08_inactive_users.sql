--------------------------------------------------------------------------------
-- File Name       : 08_inactive_users.sql
-- Category        : 27_EBS_Users_Responsibilities
-- Purpose         : Active FND users with no last_logon in 180 days
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- License and security hygiene.
--
-- EBS R12.2.x. APPS + SELECT_CATALOG_ROLE.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Stale active users
--------------------------------------------------------------------------------
-- 1. What the query does
--    END_DATE null and last_logon old.
-- 2. Important columns
--    USER_NAME, LAST_LOGON.
-- 3. How to interpret the output
--    Shared batch users may never 'log on' via FND — exclude known ones.
-- 4. What indicates a problem
--    Hundreds of stale named users.
-- 5. Recommended DBA action
--    End-date after owner approval.
-- 6. Production cautions
--    Safe.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT user_name, last_logon_date, start_date, email_address
FROM fnd_user
WHERE end_date IS NULL AND last_logon_date < SYSDATE-180
ORDER BY last_logon_date;

PROMPT
PROMPT === End of query: Stale active users ===
PROMPT

-- End of file
