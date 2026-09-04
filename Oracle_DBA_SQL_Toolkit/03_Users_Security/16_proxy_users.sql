--------------------------------------------------------------------------------
-- File Name       : 16_proxy_users.sql
-- Category        : 03_Users_Security
-- Purpose         : List proxy user relationships
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Intermediate
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Proxy authentication (ALTER USER x GRANT CONNECT THROUGH y) is used
-- by some middle tiers and OEM. Unexpected proxies are a security finding.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Proxy users
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads PROXY_USERS (or DBA_PROXIES on some versions — PROXY_USERS is the 11g+ data dictionary view).
-- 2. Important columns
--    PROXY, CLIENT, AUTHENTICATION, FLAGS.
-- 3. How to interpret the output
--    PROXY is the middle-tier account. CLIENT is the end-user schema it can connect as.
-- 4. What indicates a problem
--    A widely privileged proxy that can become APPS.
-- 5. Recommended DBA action
--    Revoke CONNECT THROUGH after confirming the app does not need it.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    SELECT on PROXY_USERS
--------------------------------------------------------------------------------
SELECT proxy, client, authentication, flags
FROM   proxy_users
ORDER BY proxy, client;

PROMPT
PROMPT === End of query: Proxy users ===
PROMPT

-- End of file
