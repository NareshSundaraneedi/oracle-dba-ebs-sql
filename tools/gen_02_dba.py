#!/usr/bin/env python3
from _writer import Query, Script, write_many


def scripts():
    return [
        Script(
            folder="02_Database_Administration",
            file_name="01_database_properties.sql",
            category="02_Database_Administration",
            purpose="List DATABASE_PROPERTIES including default tablespaces and character set",
            difficulty="Basic",
            production_use="YES",
            description="""DATABASE_PROPERTIES holds durable database-level settings that are not
all visible in V$PARAMETER (default permanent/temp tablespace, time zone).""",
            queries=[
                Query(
                    title="Database properties",
                    what="Reads DATABASE_PROPERTIES.",
                    columns="PROPERTY_NAME, PROPERTY_VALUE.",
                    interpret="DEFAULT_PERMANENT_TABLESPACE and DEFAULT_TEMP_TABLESPACE apply to new users.",
                    problem="Default permanent tablespace is SYSTEM. DBTIMEZONE unexpected after a clone.",
                    action="ALTER DATABASE DEFAULT TABLESPACE <users_ts> during a change window if SYSTEM is the default.",
                    caution="Safe to query. Changing defaults is a change.",
                    privileges="SELECT on DATABASE_PROPERTIES",
                    sql="""SELECT property_name, property_value
FROM   database_properties
ORDER BY property_name;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="02_instance_parameters.sql",
            category="02_Database_Administration",
            purpose="Show all initialization parameters with session/system modify flags",
            difficulty="Intermediate",
            production_use="YES",
            description="""Full parameter listing for audits and clone comparisons. Filter in SQL*Plus
with a substitution variable if needed.""",
            queries=[
                Query(
                    title="All parameters (optionally filtered)",
                    what="Reads V$PARAMETER. Uncomment the LIKE filter to search.",
                    columns="NAME, VALUE, ISDEFAULT, ISSYS_MODIFIABLE, ISSES_MODIFIABLE.",
                    interpret="IMMEDIATE can be changed with ALTER SYSTEM. FALSE requires a bounce.",
                    problem="A memory-only change that will vanish on restart (ISMODIFIED = SYSTEM_MOD and not in SPFILE).",
                    action="Document intended values. Persist with SCOPE=SPFILE/BOTH in a change window.",
                    caution="Safe. Do not ALTER SYSTEM here. This result set is large.",
                    privileges="SELECT on V_$PARAMETER",
                    sql="""-- Optional: DEFINE pname = %process%
SELECT
       name,
       display_value,
       isdefault,
       issys_modifiable,
       isses_modifiable,
       ismodified,
       isadjusted,
       description
FROM   v$parameter
-- WHERE name LIKE '&pname'
ORDER BY name;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="03_hidden_parameters.sql",
            category="02_Database_Administration",
            purpose="List underscore parameters that have been explicitly set",
            difficulty="Advanced",
            production_use="YES",
            description="""Underscore parameters must be Oracle Support approved. This script lists
only those present in the SPFILE/session, not the thousands of defaults.""",
            extra_header="Do not set underscore parameters without an SR or documented MOS note.",
            queries=[
                Query(
                    title="Specified hidden parameters",
                    what="Reads V$SPPARAMETER and X$KSPPI/X$KSPPCV for underscore parameters that are specified.",
                    columns="NAME, VALUE, ISDEFAULT, ISSES_MODIFIABLE.",
                    interpret="An underscore parameter that is not in the approved baseline is a risk during RU apply.",
                    problem="Forgotten underscore leftovers after a one-off workaround (_allow_resetlogs_corruption, optimizer fixes).",
                    action="Review each with Support. Remove obsolete ones during the next bounce window.",
                    caution="Querying X$ requires SYS. Do not change underscore parameters from this script.",
                    privileges="SYSDBA or SELECT on X$KSPPI / X$KSPPCV",
                    notes="Requires SYS access. Oracle 19c.",
                    sql="""-- Preferred: what is actually specified in the SPFILE
SELECT sid, name, display_value
FROM   v$spparameter
WHERE  specified = 'TRUE'
AND    name LIKE '\\_%' ESCAPE '\\'
ORDER BY name, sid;

-- Full decoded list (SYS only). Comment out if you are not SYS.
-- SELECT
--        ksppinm  AS name,
--        ksppstvl AS value,
--        ksppstdf AS isdefault
-- FROM   x$ksppi a, x$ksppcv b
-- WHERE  a.indx = b.indx
-- AND    ksppinm LIKE '\\_%' ESCAPE '\\'
-- AND    ksppstdf = 'FALSE'
-- ORDER BY ksppinm;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="04_pdb_information.sql",
            category="02_Database_Administration",
            purpose="List pluggable databases, open mode, and recovery status",
            difficulty="Intermediate",
            production_use="YES",
            description="""For CDB deployments (including some EBS 12.2 on 19c CDB architectures).
Non-CDB databases return no V$PDBS rows.""",
            queries=[
                Query(
                    title="PDB inventory",
                    what="Reads V$PDBS and CDB_PDBS.",
                    columns="NAME, OPEN_MODE, RESTRICTED, TOTAL_SIZE, RECOVERY_STATUS.",
                    interpret="READ WRITE + RESTRICTED NO is normal for an application PDB.",
                    problem="PDB saved state not OPEN, so it stays MOUNTED after CDB bounce.",
                    action="ALTER PLUGGABLE DATABASE <pdb> SAVE STATE after a planned open. Investigate alert log if open fails.",
                    caution="Safe. Opening/closing PDBs is a change.",
                    privileges="SELECT on V_$PDBS, CDB_PDBS",
                    notes="CDB only. Harmless no-rows on non-CDB.",
                    sql="""SELECT
       con_id,
       name,
       open_mode,
       restricted,
       open_time,
       total_size,
       block_size,
       recovery_status
FROM   v$pdbs
ORDER BY con_id;

SELECT pdb_name, status, creation_time, refresh_mode
FROM   cdb_pdbs
ORDER BY pdb_id;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="05_cdb_information.sql",
            category="02_Database_Administration",
            purpose="Show CDB vs non-CDB and container context",
            difficulty="Basic",
            production_use="YES",
            description="""Confirms whether you are connected to a CDB$ROOT, a PDB, or a non-CDB.
Many diagnostic views must be queried from the correct container.""",
            queries=[
                Query(
                    title="Container context",
                    what="Uses V$DATABASE.CDB and SYS_CONTEXT USERENV values.",
                    columns="CDB, CON_ID, CON_NAME, SESSION_USER.",
                    interpret="CDB=YES and CON_NAME=CDB$ROOT means you are not seeing PDB-local objects unless using CDB_* views.",
                    problem="Running EBS object queries in CDB$ROOT — they return nothing or SYS objects only.",
                    action="ALTER SESSION SET CONTAINER = <pdb>; or connect to the PDB service.",
                    caution="Safe.",
                    privileges="SELECT on V_$DATABASE",
                    sql="""SELECT
       d.name,
       d.cdb,
       SYS_CONTEXT('USERENV','CON_ID')   AS con_id,
       SYS_CONTEXT('USERENV','CON_NAME') AS con_name,
       SYS_CONTEXT('USERENV','SESSION_USER') AS session_user,
       SYS_CONTEXT('USERENV','CDB_NAME') AS cdb_name
FROM   v$database d;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="06_alert_log_location.sql",
            category="02_Database_Administration",
            purpose="Locate the ADR alert log XML and text files",
            difficulty="Basic",
            production_use="YES",
            description="""In 11g+ the alert log lives under DIAGNOSTIC_DEST. This script prints
the exact paths so you can tail the correct file on the correct RAC node.""",
            queries=[
                Query(
                    title="ADR home and alert log path",
                    what="Reads V$DIAG_INFO for Diag Trace and Diag Alert.",
                    columns="INST_ID, NAME, VALUE.",
                    interpret="Diag Trace contains alert_<sid>.log. Diag Alert contains log.xml.",
                    problem="Tailing an old ORACLE_HOME/rdbms/log/alert file that is no longer written.",
                    action="Use the Diag Trace path. On RAC, repeat on each node (paths differ by hostname).",
                    caution="Safe. Reading the alert log is OS-level after you have the path.",
                    privileges="SELECT on GV_$DIAG_INFO",
                    sql="""SELECT inst_id, name, value
FROM   gv$diag_info
WHERE  name IN ('ADR Base','ADR Home','Diag Trace','Diag Alert','Default Trace File','Active Problem Count','Active Incident Count')
ORDER BY inst_id, name;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="07_diagnostic_dest.sql",
            category="02_Database_Administration",
            purpose="Show diagnostic_dest and ADR size pressure",
            difficulty="Intermediate",
            production_use="YES",
            description="""ADR can fill the volume that holds DIAGNOSTIC_DEST (incidents, cdumps,
HM reports). Full ADR does not crash the database but blocks packaging
and can fill the disk if it shares ORACLE_BASE.""",
            queries=[
                Query(
                    title="diagnostic_dest and incident counts",
                    what="Shows diagnostic_dest and active problem/incident counts from V$DIAG_INFO.",
                    columns="DIAGNOSTIC_DEST, Active Problem Count, Active Incident Count.",
                    interpret="A rising incident count after ORA-00600/07445 storms needs purge (adrci) and root-cause work.",
                    problem="Active Incident Count in the hundreds. diagnostic_dest on a small root volume.",
                    action="Use adrci purge after capturing needed incidents. Move diagnostic_dest only with a bounce and a plan.",
                    caution="Safe. adrci purge is an operational action — not executed here.",
                    privileges="SELECT on V_$PARAMETER, V_$DIAG_INFO",
                    sql="""SELECT name, value FROM v$parameter WHERE name = 'diagnostic_dest';

SELECT name, value
FROM   v$diag_info
WHERE  name IN ('ADR Base','ADR Home','Active Problem Count','Active Incident Count');""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="08_fra_usage.sql",
            category="02_Database_Administration",
            purpose="Fast Recovery Area usage and reclaimable space",
            difficulty="Intermediate",
            production_use="YES",
            description="""A full FRA suspends archiving (database hangs on log switch). This is
a top production check. Warning bands: 70 monitor, 85 warning, 95 critical.""",
            queries=[
                Query(
                    title="FRA size, usage, and file types",
                    what="Reads V$RECOVERY_FILE_DEST and V$FLASH_RECOVERY_AREA_USAGE (V$RECOVERY_AREA_USAGE on 11g+).",
                    columns="SPACE_LIMIT, SPACE_USED, SPACE_RECLAIMABLE, FILE_TYPE, PERCENT_SPACE_USED.",
                    interpret="SPACE_RECLAIMABLE is obsolete backups/archivelogs that Oracle can delete when policy allows. Used-reclaimable is the true pressure.",
                    problem="PERCENT_SPACE_USED > 85 with little reclaimable — archive dest will soon fail.",
                    action="Back up and delete archivelogs (RMAN), raise db_recovery_file_dest_size, or move obsolete backups. Do not delete FRA files at OS level.",
                    caution="Safe to query. OS deletes of FRA files corrupt the FRA inventory.",
                    privileges="SELECT on V_$RECOVERY_FILE_DEST, V_$RECOVERY_AREA_USAGE, V_$PARAMETER",
                    sql="""SELECT name, value
FROM   v$parameter
WHERE  name IN ('db_recovery_file_dest','db_recovery_file_dest_size');

SELECT
       name,
       ROUND(space_limit / 1024 / 1024 / 1024, 2) AS limit_gb,
       ROUND(space_used / 1024 / 1024 / 1024, 2) AS used_gb,
       ROUND(space_reclaimable / 1024 / 1024 / 1024, 2) AS reclaimable_gb,
       ROUND(space_used * 100 / NULLIF(space_limit, 0), 1) AS used_pct,
       CASE
         WHEN space_used * 100 / NULLIF(space_limit, 0) > 95 THEN 'CRITICAL'
         WHEN space_used * 100 / NULLIF(space_limit, 0) > 85 THEN 'WARNING'
         WHEN space_used * 100 / NULLIF(space_limit, 0) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level,
       number_of_files
FROM   v$recovery_file_dest;

SELECT
       file_type,
       percent_space_used,
       percent_space_reclaimable,
       number_of_files
FROM   v$recovery_area_usage
ORDER BY percent_space_used DESC;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="09_recyclebin.sql",
            category="02_Database_Administration",
            purpose="Show recyclebin contents and space they occupy",
            difficulty="Intermediate",
            production_use="YES",
            description="""Dropped tables remain in the recyclebin and consume space. EBS sites
often disable recyclebin. Purging is destructive and is only generated.""",
            queries=[
                Query(
                    title="Recyclebin usage by owner",
                    what="Reads DBA_RECYCLEBIN and the recyclebin parameter.",
                    columns="OWNER, TYPE, SPACE_MB, OBJECT_NAME, ORIGINAL_NAME.",
                    interpret="Large recyclebin objects can make a tablespace look full.",
                    problem="Dropped multi-GB tables sitting in recyclebin during a space incident.",
                    action="PURGE is destructive. Generate the command, get approval, then run it manually.",
                    caution="WARNING: PURGE RECYCLEBIN / PURGE DBA_RECYCLEBIN cannot be undone. Generated only.",
                    privileges="SELECT on DBA_RECYCLEBIN, V_$PARAMETER",
                    sql="""SELECT name, value FROM v$parameter WHERE name = 'recyclebin';

SELECT
       owner,
       type,
       COUNT(*) AS objects,
       ROUND(SUM(space) * 8 / 1024, 1) AS approx_mb
FROM   dba_recyclebin
GROUP BY owner, type
ORDER BY approx_mb DESC NULLS LAST;

-- WARNING: Review carefully before executing. Generates purge commands only.
SELECT 'PURGE TABLE ' || owner || '."' || object_name || '";' AS purge_cmd
FROM   dba_recyclebin
WHERE  type = 'TABLE'
AND    space > 0
ORDER BY space DESC;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="10_database_links.sql",
            category="02_Database_Administration",
            purpose="Inventory database links",
            difficulty="Intermediate",
            production_use="YES",
            description="""DB links are a security and performance surface. EBS may have links for
tax, planning, or custom integrations. Stale links cause distributed
transaction hangs.""",
            queries=[
                Query(
                    title="DBA database links",
                    what="Reads DBA_DB_LINKS. Passwords are never shown.",
                    columns="OWNER, DB_LINK, USERNAME, HOST, CREATED.",
                    interpret="HOST is the TNS connect string. USERNAME is the remote authenticated user.",
                    problem="Public links with high-privilege remote users. Links pointing at decommissioned databases.",
                    action="Test with a SELECT * FROM dual@link in a controlled session. Drop unused links only with approval.",
                    caution="Safe to list. Opening a link creates a remote session and may fail if the network is blocked.",
                    privileges="SELECT on DBA_DB_LINKS",
                    sql="""SELECT
       owner,
       db_link,
       username,
       host,
       created
FROM   dba_db_links
ORDER BY owner, db_link;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="11_directories.sql",
            category="02_Database_Administration",
            purpose="List Oracle directory objects and who can write them",
            difficulty="Intermediate",
            production_use="YES",
            description="""Directories are used by Datapump, BFILE, and EBS concurrent programs
that write OS files. A wrong path after a clone is a common outage.""",
            queries=[
                Query(
                    title="Directories and grants",
                    what="Reads DBA_DIRECTORIES and DBA_TAB_PRIVS for directory grants.",
                    columns="DIRECTORY_NAME, DIRECTORY_PATH, GRANTEE, PRIVILEGE.",
                    interpret="APPS typically needs READ/WRITE on several utl_file directories.",
                    problem="Path pointing at the source environment after a clone. PUBLIC WRITE on a sensitive path.",
                    action="CREATE OR REPLACE DIRECTORY in a change window. Fix grants to least privilege.",
                    caution="Safe. Creating directories is a change and requires OS path existence.",
                    privileges="SELECT on DBA_DIRECTORIES, DBA_TAB_PRIVS",
                    ebs="Useful for EBS",
                    sql="""SELECT directory_name, directory_path
FROM   dba_directories
ORDER BY directory_name;

SELECT
       p.grantee,
       p.table_name AS directory_name,
       p.privilege,
       p.grantable
FROM   dba_tab_privs p
JOIN   dba_directories d ON d.directory_name = p.table_name
WHERE  p.privilege IN ('READ','WRITE','EXECUTE')
ORDER BY p.table_name, p.grantee, p.privilege;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="12_jobs_scheduler.sql",
            category="02_Database_Administration",
            purpose="List DBMS_SCHEDULER jobs and DBMS_JOB leftovers",
            difficulty="Intermediate",
            production_use="YES",
            description="""Covers both DBMS_SCHEDULER (recommended) and legacy DBMS_JOB.
EBS concurrent processing is NOT listed here — see folder 21.""",
            queries=[
                Query(
                    title="Scheduler jobs and running jobs",
                    what="Reads DBA_SCHEDULER_JOBS, DBA_SCHEDULER_RUNNING_JOBS, and DBA_JOBS.",
                    columns="JOB_NAME, ENABLED, STATE, LAST_START_DATE, NEXT_RUN_DATE, FAILURE_COUNT.",
                    interpret="STATE BROKEN or FAILURE_COUNT rising needs investigation. EBS Gather Stats may appear as a scheduler job.",
                    problem="A custom job running heavy SQL during peak. Broken auto-stats job.",
                    action="Disable with DBMS_SCHEDULER.DISABLE only after approval. Do not drop jobs from this script.",
                    caution="Safe to query. Disabling jobs is a change.",
                    privileges="SELECT on DBA_SCHEDULER_JOBS, DBA_SCHEDULER_RUNNING_JOBS, DBA_JOBS",
                    sql="""SELECT
       owner,
       job_name,
       job_type,
       enabled,
       state,
       failure_count,
       last_start_date,
       next_run_date,
       run_count
FROM   dba_scheduler_jobs
WHERE  enabled = 'TRUE'
OR     state NOT IN ('SCHEDULED','DISABLED')
ORDER BY owner, job_name;

SELECT owner, job_name, session_id, running_instance, elapsed_time, cpu_used
FROM   dba_scheduler_running_jobs;

SELECT job, log_user, schema_user, broken, failures, next_date, interval, what
FROM   dba_jobs
ORDER BY job;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="13_resource_limits.sql",
            category="02_Database_Administration",
            purpose="Compare processes/sessions usage against initialization limits",
            difficulty="Intermediate",
            production_use="YES",
            description="""ORA-00018 / ORA-00020 occur when sessions or processes hit the
initialization parameter. Check this during connection storms.""",
            queries=[
                Query(
                    title="Processes and sessions utilization",
                    what="Joins V$RESOURCE_LIMIT with current counts.",
                    columns="RESOURCE_NAME, CURRENT_UTILIZATION, MAX_UTILIZATION, LIMIT_VALUE.",
                    interpret="CURRENT close to LIMIT is an imminent outage. MAX_UTILIZATION shows the high-water mark since startup.",
                    problem="CURRENT_UTILIZATION / LIMIT > 85% for processes or sessions.",
                    action="Increase processes (and sessions, which defaults to processes*1.5) in a bounce window, or find the connection leak.",
                    caution="Safe. Raising processes needs more process memory and a bounce if not dynamic enough on your version — on 19c processes is not dynamic.",
                    privileges="SELECT on V_$RESOURCE_LIMIT, V_$PARAMETER",
                    sql="""SELECT
       resource_name,
       current_utilization,
       max_utilization,
       initial_allocation,
       limit_value,
       CASE
         WHEN REGEXP_LIKE(limit_value, '^[0-9]+$')
          AND current_utilization * 100 / TO_NUMBER(limit_value) > 95 THEN 'CRITICAL'
         WHEN REGEXP_LIKE(limit_value, '^[0-9]+$')
          AND current_utilization * 100 / TO_NUMBER(limit_value) > 85 THEN 'WARNING'
         WHEN REGEXP_LIKE(limit_value, '^[0-9]+$')
          AND current_utilization * 100 / TO_NUMBER(limit_value) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   v$resource_limit
WHERE  resource_name IN ('processes','sessions','transactions','enqueue_locks','dml_locks','max_shared_servers')
ORDER BY resource_name;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="14_feature_usage.sql",
            category="02_Database_Administration",
            purpose="Show DBA_FEATURE_USAGE_STATISTICS for licensing awareness",
            difficulty="Advanced",
            production_use="YES",
            description="""Lists features Oracle thinks have been used. This is NOT a license
audit by itself, but DETECTED_USAGES > 0 on Pack features is a flag
to discuss with license management.""",
            extra_header="Diagnostics Pack / Tuning Pack: AWR, ASH, ADDM, SQL Tuning Advisor usage appears here.",
            queries=[
                Query(
                    title="Feature usage (currently used)",
                    what="Reads DBA_FEATURE_USAGE_STATISTICS for currently_used = TRUE.",
                    columns="NAME, CURRENTLY_USED, DETECTED_USAGES, LAST_USAGE_DATE.",
                    interpret="AWR / SQL Monitoring / Tuning Pack rows with CURRENTLY_USED TRUE mean those packs have been exercised.",
                    problem="Pack features used on Standard Edition or unlicensed EE options.",
                    action="Stop unlicensed feature use. This script does not enable or disable anything.",
                    caution="Safe. Do not treat this as a legal license report.",
                    privileges="SELECT on DBA_FEATURE_USAGE_STATISTICS",
                    notes="Licensing: this view itself is in the dictionary; some listed features require packs.",
                    sql="""SELECT
       name,
       version,
       currently_used,
       detected_usages,
       last_usage_date,
       first_usage_date
FROM   dba_feature_usage_statistics
WHERE  currently_used = 'TRUE'
ORDER BY name;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="15_patch_registry.sql",
            category="02_Database_Administration",
            purpose="Combine SQL patch registry with opatch-equivalent inventory in-db",
            difficulty="Intermediate",
            production_use="YES",
            description="""In-database view of datapatch history plus DBA_REGISTRY status.
OS opatch lsinventory remains required for binary one-offs.""",
            queries=[
                Query(
                    title="SQL patches and registry status",
                    what="Joins DBA_REGISTRY_SQLPATCH with invalid DBA_REGISTRY components.",
                    columns="PATCH_ID, STATUS, ACTION, COMP_ID, COMP_STATUS.",
                    interpret="Binary patched + SQL WITH ERRORS is a half-patched database.",
                    problem="Any component INVALID after a patch window.",
                    action="Rerun datapatch. Review sqlpatch logs. Do not start EBS services until VALID.",
                    caution="Safe.",
                    privileges="SELECT on DBA_REGISTRY_SQLPATCH, DBA_REGISTRY",
                    sql="""SELECT patch_id, version, status, action, description, action_time
FROM   dba_registry_sqlpatch
ORDER BY action_time DESC;

SELECT comp_id, comp_name, version, status
FROM   dba_registry
WHERE  status <> 'VALID'
ORDER BY comp_id;""",
                )
            ],
        ),
        Script(
            folder="02_Database_Administration",
            file_name="16_option_status.sql",
            category="02_Database_Administration",
            purpose="Show installed Oracle options (RAC, Partitioning, etc.)",
            difficulty="Basic",
            production_use="YES",
            description="""V$OPTION lists whether options are linked into the binary.
VALUE TRUE does not automatically mean you are licensed to use them.""",
            queries=[
                Query(
                    title="V$OPTION inventory",
                    what="Reads V$OPTION.",
                    columns="PARAMETER, VALUE.",
                    interpret="Real Application Clusters TRUE means RAC is linked. Partitioning TRUE is common on EE.",
                    problem="An option you rely on (Partitioning, Advanced Compression) showing FALSE after a relink.",
                    action="Relink options only with Support guidance. License questions go to contract management.",
                    caution="Safe.",
                    privileges="SELECT on V_$OPTION",
                    sql="""SELECT parameter, value
FROM   v$option
ORDER BY parameter;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
