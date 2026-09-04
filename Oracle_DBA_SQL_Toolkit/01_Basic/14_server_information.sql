--------------------------------------------------------------------------------
-- File Name       : 14_server_information.sql
-- Category        : 01_Basic
-- Purpose         : CPU, platform, and instance resource snapshot
-- Oracle Version  : 19c
-- EBS Version     : R12.2.x where applicable
-- Difficulty      : Basic
-- Production Use  : YES
--------------------------------------------------------------------------------
-- DESCRIPTION
-- Shows platform, CPU count visible to Oracle, and basic resource
-- parameters. Useful when comparing a clone to production or after
-- a VM resize.
--------------------------------------------------------------------------------
SET LINESIZE 300
SET PAGESIZE 100
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
COLUMN status FORMAT A20

--------------------------------------------------------------------------------
-- QUERY 1: Platform and CPU visible to Oracle
--------------------------------------------------------------------------------
-- 1. What the query does
--    Reads V$DATABASE.PLATFORM_NAME and CPU-related parameters / V$OSSTAT.
-- 2. Important columns
--    PLATFORM_NAME, CPU_COUNT, CPU_CORE_COUNT, NUM_CPUS, PHYSICAL_MEMORY_BYTES.
-- 3. How to interpret the output
--    CPU_COUNT is what the optimizer and Resource Manager see. After a vCPU change, Oracle may need a bounce for CPU_COUNT to update unless cpu_count is explicitly set.
-- 4. What indicates a problem
--    cpu_count parameter hard-coded below actual CPUs after a hardware upgrade. Huge mismatch vs OS lscpu.
-- 5. Recommended DBA action
--    If cpu_count is explicitly set, raise a change to align it. Do not alter in production without approval.
-- 6. Production cautions
--    Safe. PHYSICAL_MEMORY_BYTES is instance view of RAM, not hugepages allocation.
-- 7. Required privileges
--    SELECT on V_$DATABASE, V_$PARAMETER, V_$OSSTAT
--------------------------------------------------------------------------------
SELECT platform_name, platform_id FROM v$database;

SELECT name, value
FROM   v$parameter
WHERE  name IN ('cpu_count','cpu_min_count','parallel_threads_per_cpu','memory_target','sga_target','pga_aggregate_target');

SELECT stat_name, value
FROM   v$osstat
WHERE  stat_name IN ('NUM_CPUS','NUM_CPU_CORES','NUM_CPU_SOCKETS','PHYSICAL_MEMORY_BYTES','LOAD');

PROMPT
PROMPT === End of query: Platform and CPU visible to Oracle ===
PROMPT

-- End of file
