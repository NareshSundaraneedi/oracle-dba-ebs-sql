--------------------------------------------------------------------------------
-- File Name       : 07_workflow_agent_listeners.sql
-- Category        : 23_EBS_Workflows
-- Purpose         : Workflow agent listeners / service components (R12.2 OAM)
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x
-- Difficulty      : Advanced
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- FND_SVC_COMPONENTS shows Workflow Agent Listener, Mailer, etc. Container is usually the Service Manager.
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
-- QUERY 1: Service components
--------------------------------------------------------------------------------
-- 1. What the query does
--    FND_SVC_COMPONENTS and FND_SVC_COMP_TYPES_VL.
-- 2. Important columns
--    COMPONENT_NAME, STARTUP_MODE, COMPONENT_STATUS.
-- 3. How to interpret the output
--    STATUS RUNNING_OK / STOPPED. Mailer down = no email notifications.
-- 4. What indicates a problem
--    Workflow Agent Listener STOPPED — business events / AQ stall.
-- 5. Recommended DBA action
--    Start from OAM / Service Components. Check container log. SQL start is not supported.
-- 6. Production cautions
--    Safe to query.
-- 7. Required privileges
--    APPS
--------------------------------------------------------------------------------
SELECT component_name, component_status, startup_mode, component_type,
       inbound_agent_name, outbound_agent_name
FROM fnd_svc_components
ORDER BY component_type, component_name;

SELECT component_name, component_status
FROM fnd_svc_components
WHERE UPPER(component_name) LIKE '%MAILER%'
   OR UPPER(component_name) LIKE '%LISTEN%'
   OR UPPER(component_type) LIKE '%WORKFLOW%';

PROMPT
PROMPT === End of query: Service components ===
PROMPT

-- End of file
