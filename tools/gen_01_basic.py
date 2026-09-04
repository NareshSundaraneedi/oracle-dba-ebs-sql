#!/usr/bin/env python3
from _writer import Query, Script, write_many


def scripts():
    return [
        Script(
            folder="01_Basic",
            file_name="01_database_name.sql",
            category="01_Basic",
            purpose="Identify the current database name and unique name",
            difficulty="Basic",
            production_use="YES",
            ebs="N/A",
            privileges="SELECT on V_$DATABASE",
            description="""Returns the database name (DB_NAME) and unique name (DB_UNIQUE_NAME).
Use this first in any incident so you confirm you are connected to the intended
primary, standby, or cloned environment before changing anything.""",
            queries=[
                Query(
                    title="Database name and unique name",
                    what="Reads V$DATABASE for NAME and DB_UNIQUE_NAME and shows the session container.",
                    columns="DB_NAME, DB_UNIQUE_NAME, DBID, CREATED, CON_ID, CON_NAME (if CDB).",
                    interpret="DB_NAME is the short database name. DB_UNIQUE_NAME distinguishes Data Guard members and clones that share the same DB_NAME.",
                    problem="DB_UNIQUE_NAME not matching the ticket environment means you are on the wrong database.",
                    action="Reconnect using the correct TNS alias / service. Do not proceed with changes until names match the change record.",
                    caution="Read-only. Safe on production. In a CDB, confirm you are in the intended PDB with SHOW CON_NAME.",
                    privileges="SELECT_CATALOG_ROLE or SELECT on V_$DATABASE",
                    sql="""SELECT
       d.name              AS db_name,
       d.db_unique_name    AS db_unique_name,
       d.dbid,
       d.created,
       d.cdb,
       SYS_CONTEXT('USERENV','CON_NAME') AS con_name,
       SYS_CONTEXT('USERENV','CON_ID')   AS con_id
FROM   v$database d;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="02_dbid.sql",
            category="01_Basic",
            purpose="Display DBID used by RMAN, AWR, and Data Guard",
            difficulty="Basic",
            production_use="YES",
            description="""The DBID uniquely identifies a database incarnation for RMAN catalogs,
AWR repositories, and some Data Guard operations. Capture it before any
restore, duplicate, or catalog resync.""",
            queries=[
                Query(
                    title="Current DBID and incarnation",
                    what="Returns DBID from V$DATABASE plus current incarnation from V$DATABASE_INCARNATION.",
                    columns="DBID, RESETLOGS_CHANGE#, RESETLOGS_TIME, INCARNATION#, STATUS.",
                    interpret="CURRENT incarnation is the one RMAN will use unless you RESET DATABASE TO INCARNATION.",
                    problem="A recent RESETLOGS without a new full backup breaks recoverability to the previous incarnation.",
                    action="Record DBID in the runbook. After RESETLOGS, take a fresh level 0 backup immediately.",
                    caution="Read-only. Do not confuse DBID with CON_DBID of a PDB.",
                    privileges="SELECT on V_$DATABASE, V_$DATABASE_INCARNATION",
                    sql="""SELECT
       d.dbid,
       d.name,
       d.resetlogs_change#,
       d.resetlogs_time,
       i.incarnation#,
       i.status            AS incarnation_status,
       i.resetlogs_id
FROM   v$database d
JOIN   v$database_incarnation i
       ON i.status = 'CURRENT';""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="03_instance_name.sql",
            category="01_Basic",
            purpose="Show instance name, number, and thread",
            difficulty="Basic",
            production_use="YES",
            description="""Identifies which instance the session is connected to. Critical on RAC
where the same service can land on any node.""",
            queries=[
                Query(
                    title="Current instance identity",
                    what="Reads V$INSTANCE for instance name, number, host, and thread.",
                    columns="INSTANCE_NAME, INSTANCE_NUMBER, HOST_NAME, THREAD#, STATUS, DATABASE_STATUS.",
                    interpret="INSTANCE_NUMBER maps to GV$ views. THREAD# maps to redo threads.",
                    problem="Connected to a different RAC node than the one showing the symptom (for example, local temp pressure).",
                    action="Reconnect with INSTANCE_NAME in the connect string or use GV$ views for cluster-wide checks.",
                    caution="Safe. On RAC prefer GV$INSTANCE when comparing all nodes.",
                    privileges="SELECT on V_$INSTANCE",
                    sql="""SELECT
       instance_name,
       instance_number,
       host_name,
       thread#,
       status,
       database_status,
       archiver,
       logins,
       shutdown_pending
FROM   v$instance;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="04_host_name.sql",
            category="01_Basic",
            purpose="Identify the database server host for the current instance",
            difficulty="Basic",
            production_use="YES",
            description="""Shows the host name reported by the Oracle instance. Use it to confirm
OS-level work (alert log, OSWatcher, hugepages) is being done on the
correct server.""",
            queries=[
                Query(
                    title="Host name for this instance and all RAC instances",
                    what="Returns HOST_NAME from V$INSTANCE and GV$INSTANCE.",
                    columns="INST_ID, INSTANCE_NAME, HOST_NAME, STARTUP_TIME.",
                    interpret="Each RAC node has its own HOST_NAME. Single-instance databases return one row from GV$.",
                    problem="Alert log or OS metrics collected from a different host than the instance serving the workload.",
                    action="Collect diagnostics from the host(s) listed here. For RAC, collect from every node.",
                    caution="HOST_NAME is the Oracle-reported name and may be a short name, not the FQDN.",
                    privileges="SELECT on GV_$INSTANCE",
                    sql="""SELECT
       inst_id,
       instance_name,
       host_name,
       startup_time,
       status
FROM   gv$instance
ORDER BY inst_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="05_database_version.sql",
            category="01_Basic",
            purpose="Show Oracle database version, RU, and compatible setting",
            difficulty="Basic",
            production_use="YES",
            description="""Confirms the software version, Release Update, and COMPATIBLE parameter.
Required before applying patches, using new 19c features, or opening a
standby created from a different RU.""",
            queries=[
                Query(
                    title="Banner, version, and compatible",
                    what="Reads V$VERSION, V$INSTANCE.VERSION, and the COMPATIBLE parameter.",
                    columns="BANNER, VERSION_FULL (19c+), COMPATIBLE, STATUS.",
                    interpret="VERSION_FULL includes the RU (for example 19.21.0.0.0). COMPATIBLE controls on-disk compatibility, not the binary version.",
                    problem="COMPATIBLE far below the binary version blocks new features. Mixed RU across RAC nodes is unsupported.",
                    action="Align RU across all RAC/DG members. Raise COMPATIBLE only after a full backup and change approval.",
                    caution="V$VERSION.BANNER_FULL / VERSION_FULL exist in 18c/19c. Older 12.1 databases only have BANNER.",
                    privileges="SELECT on V_$VERSION, V_$INSTANCE, V_$PARAMETER",
                    notes="Oracle 19c.",
                    sql="""SELECT banner FROM v$version;

SELECT version, version_full, status
FROM   v$instance;

SELECT name, value
FROM   v$parameter
WHERE  name IN ('compatible','cpu_count','db_name');""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="06_oracle_home.sql",
            category="01_Basic",
            purpose="Locate ORACLE_HOME and ORACLE_BASE used by the instance",
            difficulty="Basic",
            production_use="YES",
            description="""Shows the Oracle home the running instance was started from. Essential
when multiple homes exist (for example 19c gold image vs old home).""",
            queries=[
                Query(
                    title="Oracle home from V$PARAMETER and SYS_CONTEXT",
                    what="Derives ORACLE_HOME from the SPFILE/background dump path and session environment.",
                    columns="ORACLE_HOME (derived), DIAGNOSTIC_DEST, SPFILE.",
                    interpret="The running instance home may differ from the shell ORACLE_HOME of your SQL*Plus session.",
                    problem="Patching or opatch lsinventory run against a different home than the running instance.",
                    action="Use the home reported here for opatch, relink, and listener configuration.",
                    caution="V$PARAMETER.VALUE for diagnostic_dest is ORACLE_BASE/diag in 11g+ ADR.",
                    privileges="SELECT on V_$PARAMETER",
                    sql="""SELECT
       SYS_CONTEXT('USERENV','ORACLE_HOME') AS oracle_home,
       (SELECT value FROM v$parameter WHERE name = 'diagnostic_dest') AS diagnostic_dest,
       (SELECT value FROM v$parameter WHERE name = 'spfile')          AS spfile,
       (SELECT value FROM v$parameter WHERE name = 'background_dump_dest') AS background_dump_dest
FROM   dual;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="07_startup_time.sql",
            category="01_Basic",
            purpose="Show instance startup time",
            difficulty="Basic",
            production_use="YES",
            description="""Returns when the instance last started. Use it to correlate incidents
with bounces, crashes, or patch windows.""",
            queries=[
                Query(
                    title="Startup time per instance",
                    what="Reads STARTUP_TIME from GV$INSTANCE.",
                    columns="INST_ID, INSTANCE_NAME, STARTUP_TIME.",
                    interpret="A recent startup after an unexplained outage usually indicates a crash or ORA-600 bounce.",
                    problem="Unexpected restart. On RAC, one instance restarting while others stay up points to a local node issue.",
                    action="Check alert log around STARTUP_TIME for ORA-00600/07445, instance eviction, or ORA-29740.",
                    caution="Safe. Startup time resets AWR baseline comparisons unless you use a preserved snapshot set.",
                    privileges="SELECT on GV_$INSTANCE",
                    sql="""SELECT
       inst_id,
       instance_name,
       startup_time,
       ROUND((SYSDATE - startup_time) * 24, 2) AS hours_up
FROM   gv$instance
ORDER BY inst_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="08_database_uptime.sql",
            category="01_Basic",
            purpose="Calculate instance uptime in days, hours, and minutes",
            difficulty="Basic",
            production_use="YES",
            description="""Human-readable uptime. Use during capacity reviews and after patching
to confirm the instance stayed up.""",
            queries=[
                Query(
                    title="Formatted instance uptime",
                    what="Computes days/hours/minutes since STARTUP_TIME.",
                    columns="INST_ID, STARTUP_TIME, DAYS, HOURS, MINUTES.",
                    interpret="Short uptime after a planned bounce is expected. Short uptime without a change record is an incident.",
                    problem="Repeated short uptimes indicate instability (memory, clusterware, storage).",
                    action="If unplanned, pull alert log, OS messages, and Clusterware logs for the restart time.",
                    caution="Safe. Does not include database MOUNT time separately from OPEN.",
                    privileges="SELECT on GV_$INSTANCE",
                    sql="""SELECT
       inst_id,
       instance_name,
       startup_time,
       TRUNC(SYSDATE - startup_time) AS days,
       TRUNC(MOD((SYSDATE - startup_time) * 24, 24)) AS hours,
       TRUNC(MOD((SYSDATE - startup_time) * 24 * 60, 60)) AS minutes,
       ROUND((SYSDATE - startup_time) * 24, 2) AS total_hours
FROM   gv$instance
ORDER BY inst_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="09_database_role.sql",
            category="01_Basic",
            purpose="Show primary / standby / snapshot standby role",
            difficulty="Basic",
            production_use="YES",
            description="""DATABASE_ROLE tells you whether this database is PRIMARY, PHYSICAL STANDBY,
LOGICAL STANDBY, or SNAPSHOT STANDBY. Never run DML or application
cutover checks until role is confirmed.""",
            queries=[
                Query(
                    title="Database role and open mode",
                    what="Reads DATABASE_ROLE, OPEN_MODE, PROTECTION_MODE from V$DATABASE.",
                    columns="DATABASE_ROLE, OPEN_MODE, PROTECTION_MODE, SWITCHOVER_STATUS, DATAGUARD_BROKER.",
                    interpret="PRIMARY + READ WRITE is a normal production primary. PHYSICAL STANDBY is usually MOUNTED or OPEN READ ONLY (Active Data Guard).",
                    problem="Role is SNAPSHOT STANDBY when you expected a physical standby (convert back before switchover). SWITCHOVER_STATUS not TO STANDBY when a switchover is planned.",
                    action="If role is unexpected, stop and verify broker / DG configuration. Do not open a standby READ WRITE unless converting to snapshot.",
                    caution="Safe. SWITCHOVER_STATUS of SESSIONS ACTIVE means you must disconnect users before switchover.",
                    privileges="SELECT on V_$DATABASE",
                    notes="Data Guard optional. Meaningful on any database that may be a DG member.",
                    sql="""SELECT
       name,
       db_unique_name,
       database_role,
       open_mode,
       protection_mode,
       protection_level,
       switchover_status,
       dataguard_broker,
       force_logging,
       flashback_on
FROM   v$database;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="10_open_mode.sql",
            category="01_Basic",
            purpose="Show database and PDB open mode",
            difficulty="Basic",
            production_use="YES",
            description="""Confirms whether the CDB and each PDB are MOUNTED, READ ONLY, or
READ WRITE. EBS R12.2 databases are typically non-CDB or a single PDB.""",
            queries=[
                Query(
                    title="CDB/non-CDB and PDB open modes",
                    what="Shows V$DATABASE.OPEN_MODE and V$PDBS open mode when running in a CDB.",
                    columns="NAME, OPEN_MODE, RESTRICTED, OPEN_TIME.",
                    interpret="EBS application connections require READ WRITE. READ ONLY is expected on an Active Data Guard standby.",
                    problem="PDB in MOUNTED or RESTRICTED YES after patching or a failed PDB open.",
                    action="ALTER PLUGGABLE DATABASE <pdb> OPEN; investigate alert log if it fails. Restricted mode blocks normal application users.",
                    caution="Safe. In a non-CDB the PDB query returns no rows — that is expected.",
                    privileges="SELECT on V_$DATABASE, V_$PDBS",
                    sql="""SELECT name, open_mode, database_role
FROM   v$database;

-- Returns rows only in a CDB
SELECT
       con_id,
       name,
       open_mode,
       restricted,
       open_time
FROM   v$pdbs
ORDER BY con_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="11_database_status.sql",
            category="01_Basic",
            purpose="High-level database health: role, mode, log mode, force logging",
            difficulty="Basic",
            production_use="YES",
            description="""Single-pane check used at the start of every shift or incident.
Combines role, open mode, archive mode, and force logging.""",
            queries=[
                Query(
                    title="Database status snapshot",
                    what="Summarizes V$DATABASE attributes that must be correct for a production EBS or RAC primary.",
                    columns="NAME, DATABASE_ROLE, OPEN_MODE, LOG_MODE, FORCE_LOGGING, FLASHBACK_ON, CONTROLFILE_TYPE.",
                    interpret="Production primary: PRIMARY, READ WRITE, ARCHIVELOG, FORCE LOGGING typically YES for Data Guard / GoldenGate.",
                    problem="NOARCHIVELOG on production. FORCE_LOGGING NO when a standby exists. CONTROLFILE_TYPE STANDBY on a database you thought was primary.",
                    action="Do not enable ARCHIVELOG or FORCE LOGGING without a change window. Escalate role mismatches immediately.",
                    caution="Safe. FORCE_LOGGING YES is expected on EBS production with Data Guard.",
                    privileges="SELECT on V_$DATABASE",
                    sql="""SELECT
       name,
       dbid,
       db_unique_name,
       database_role,
       open_mode,
       log_mode,
       force_logging,
       flashback_on,
       controlfile_type,
       checkpoint_change#,
       current_scn
FROM   v$database;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="12_instance_status.sql",
            category="01_Basic",
            purpose="Show instance status, logins, and archiver health",
            difficulty="Basic",
            production_use="YES",
            description="""V$INSTANCE.STATUS should be OPEN for an application database.
ARCHIVER FAILED or logins RESTRICTED are production incidents.""",
            queries=[
                Query(
                    title="Instance status and login mode",
                    what="Checks STATUS, ARCHIVER, LOGINS, SHUTDOWN_PENDING for all instances.",
                    columns="STATUS (STARTED/MOUNTED/OPEN), ARCHIVER, LOGINS, SHUTDOWN_PENDING, ACTIVE_STATE.",
                    interpret="OPEN + ALLOWED is normal. RESTRICTED is used during maintenance. ARCHIVER FAILED means redo cannot be archived.",
                    problem="ARCHIVER FAILED or STOPPED on a primary in ARCHIVELOG. LOGINS RESTRICTED unexpectedly. SHUTDOWN_PENDING YES.",
                    action="If archiver failed: free FRA / archive dest, then archive leftover logs. If restricted unexpectedly: ALTER SYSTEM DISABLE RESTRICTED SESSION after verifying why it was set.",
                    caution="Safe. Do not disable restricted session during a patch window.",
                    privileges="SELECT on GV_$INSTANCE",
                    sql="""SELECT
       inst_id,
       instance_name,
       status,
       database_status,
       archiver,
       logins,
       shutdown_pending,
       active_state,
       blocked
FROM   gv$instance
ORDER BY inst_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="13_rac_status.sql",
            category="01_Basic",
            purpose="Determine whether the database is RAC and list instances",
            difficulty="Basic",
            production_use="YES",
            description="""Confirms cluster_database parameter and lists all RAC instances.
Use GV$ views for subsequent diagnostics when CLUSTER_DATABASE is TRUE.""",
            queries=[
                Query(
                    title="RAC enabled and instance list",
                    what="Checks CLUSTER_DATABASE and enumerates GV$INSTANCE.",
                    columns="CLUSTER_DATABASE, INST_ID, INSTANCE_NAME, STATUS, PARALLEL.",
                    interpret="CLUSTER_DATABASE TRUE with one instance usually means a second node is down.",
                    problem="An instance in the cluster is not OPEN. PARALLEL NO on a RAC instance is unexpected.",
                    action="If a node is down, check crsctl status resource -t (from Grid home) and the cluster alert log. Do not assume SQL can start an instance.",
                    caution="Safe. crsctl commands are OS-level and are not included here.",
                    privileges="SELECT on GV_$INSTANCE, V_$PARAMETER",
                    notes="RAC where applicable.",
                    sql="""SELECT name, value
FROM   v$parameter
WHERE  name IN ('cluster_database','cluster_database_instances','instance_number');

SELECT
       inst_id,
       instance_name,
       host_name,
       status,
       parallel,
       thread#,
       startup_time
FROM   gv$instance
ORDER BY inst_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="14_server_information.sql",
            category="01_Basic",
            purpose="CPU, platform, and instance resource snapshot",
            difficulty="Basic",
            production_use="YES",
            description="""Shows platform, CPU count visible to Oracle, and basic resource
parameters. Useful when comparing a clone to production or after
a VM resize.""",
            queries=[
                Query(
                    title="Platform and CPU visible to Oracle",
                    what="Reads V$DATABASE.PLATFORM_NAME and CPU-related parameters / V$OSSTAT.",
                    columns="PLATFORM_NAME, CPU_COUNT, CPU_CORE_COUNT, NUM_CPUS, PHYSICAL_MEMORY_BYTES.",
                    interpret="CPU_COUNT is what the optimizer and Resource Manager see. After a vCPU change, Oracle may need a bounce for CPU_COUNT to update unless cpu_count is explicitly set.",
                    problem="cpu_count parameter hard-coded below actual CPUs after a hardware upgrade. Huge mismatch vs OS lscpu.",
                    action="If cpu_count is explicitly set, raise a change to align it. Do not alter in production without approval.",
                    caution="Safe. PHYSICAL_MEMORY_BYTES is instance view of RAM, not hugepages allocation.",
                    privileges="SELECT on V_$DATABASE, V_$PARAMETER, V_$OSSTAT",
                    sql="""SELECT platform_name, platform_id FROM v$database;

SELECT name, value
FROM   v$parameter
WHERE  name IN ('cpu_count','cpu_min_count','parallel_threads_per_cpu','memory_target','sga_target','pga_aggregate_target');

SELECT stat_name, value
FROM   v$osstat
WHERE  stat_name IN ('NUM_CPUS','NUM_CPU_CORES','NUM_CPU_SOCKETS','PHYSICAL_MEMORY_BYTES','LOAD');""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="15_character_set.sql",
            category="01_Basic",
            purpose="Show database and national character sets",
            difficulty="Basic",
            production_use="YES",
            description="""EBS R12.2 commonly uses AL32UTF8. Character set mismatches cause
ORA-12705, data corruption on import, and Forms display issues.""",
            queries=[
                Query(
                    title="Database and national character set",
                    what="Reads NLS_DATABASE_PARAMETERS and NLS_CHARACTERSET / NLS_NCHAR_CHARACTERSET.",
                    columns="PARAMETER, VALUE.",
                    interpret="NLS_CHARACTERSET is the database character set. NLS_NCHAR_CHARACTERSET is used for NCHAR/NVARCHAR2.",
                    problem="US7ASCII or WE8ISO8859P1 on a database expected to be AL32UTF8. Client NLS_LANG mismatch is a different problem (session, not this query).",
                    action="Character set conversion is a project (CSALTER / full export). Never change it as a quick fix.",
                    caution="Safe. Do not run CSALTER from this toolkit.",
                    privileges="SELECT on NLS_DATABASE_PARAMETERS / V$NLS_PARAMETERS",
                    ebs="Useful for EBS",
                    sql="""SELECT parameter, value
FROM   nls_database_parameters
WHERE  parameter IN (
         'NLS_CHARACTERSET',
         'NLS_NCHAR_CHARACTERSET',
         'NLS_LANGUAGE',
         'NLS_TERRITORY',
         'NLS_LENGTH_SEMANTICS',
         'NLS_RDBMS_VERSION'
       )
ORDER BY parameter;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="16_nls_parameters.sql",
            category="01_Basic",
            purpose="Compare database, instance, and session NLS settings",
            difficulty="Basic",
            production_use="YES",
            description="""NLS can be set at database, instance, and session level. Date format
and numeric characters differences are a frequent cause of EBS
interface errors and concurrent program failures.""",
            queries=[
                Query(
                    title="Database vs session NLS",
                    what="Compares NLS_DATABASE_PARAMETERS with NLS_SESSION_PARAMETERS.",
                    columns="PARAMETER, DATABASE_VALUE, SESSION_VALUE.",
                    interpret="Session values override database defaults. Concurrent managers inherit NLS from the manager environment, not from your SQL*Plus session.",
                    problem="NLS_DATE_FORMAT or NLS_NUMERIC_CHARACTERS differ from what an interface program expects (for example decimal comma).",
                    action="Fix the client / concurrent manager environment (NLS_LANG, fnd_concurrent NLS), not the database character set.",
                    caution="Safe. Changing NLS_DATABASE_PARAMETERS requires rebuild — never done here.",
                    privileges="SELECT on NLS_* views",
                    ebs="Useful for EBS",
                    sql="""SELECT
       d.parameter,
       d.value AS database_value,
       s.value AS session_value
FROM   nls_database_parameters d
LEFT JOIN nls_session_parameters s
       ON s.parameter = d.parameter
ORDER BY d.parameter;

SELECT parameter, value
FROM   nls_instance_parameters
ORDER BY parameter;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="17_database_parameters.sql",
            category="01_Basic",
            purpose="List non-default initialization parameters",
            difficulty="Basic",
            production_use="YES",
            description="""Shows parameters that differ from Oracle defaults. This is the set
you must document, compare across clones, and review after a PSU/RU.""",
            queries=[
                Query(
                    title="Non-default parameters (spfile/source aware)",
                    what="Lists V$PARAMETER rows where ISDEFAULT = FALSE, including whether they are modified at session/system level.",
                    columns="NAME, VALUE, ISDEFAULT, ISMODIFIED, ISADJUSTED, ISBASIC, UPDATE_COMMENT.",
                    interpret="ISMODIFIED SYSTEM_MOD means a runtime ALTER SYSTEM that may not be in the SPFILE if SCOPE=MEMORY was used.",
                    problem="Critical parameters (memory, processes, undo_retention, archive dest, cluster_interconnects) changed in MEMORY only — they will revert on bounce.",
                    action="Compare with the approved parameter baseline. Persist intended changes with SCOPE=SPFILE or BOTH during a change window.",
                    caution="Safe. Do not ALTER SYSTEM from this script. Underscore parameters are in 02_Database_Administration/03_hidden_parameters.sql.",
                    privileges="SELECT on V_$PARAMETER",
                    sql="""SELECT
       name,
       display_value,
       isdefault,
       issys_modifiable,
       ismodified,
       isadjusted,
       isbasic,
       description
FROM   v$parameter
WHERE  isdefault = 'FALSE'
ORDER BY name;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="18_spfile_location.sql",
            category="01_Basic",
            purpose="Locate the SPFILE the instance is using",
            difficulty="Basic",
            production_use="YES",
            description="""Confirms whether the instance started with an SPFILE (preferred) or
a PFILE, and where that SPFILE lives (file system or ASM).""",
            queries=[
                Query(
                    title="SPFILE path and pfile fallback",
                    what="Reads the SPFILE parameter and V$SPPARAMETER for the source.",
                    columns="SPFILE path, SID, NAME, VALUE, ISSPECIFIED.",
                    interpret="Empty SPFILE value means the instance started from a PFILE. ASM paths start with +.",
                    problem="Started from a PFILE after an emergency bounce — subsequent ALTER SYSTEM SCOPE=SPFILE will fail or write to an unexpected file.",
                    action="If SPFILE is missing, recreate it from the approved pfile during a change window: CREATE SPFILE FROM PFILE.",
                    caution="Safe. Creating an SPFILE is a change — not executed here.",
                    privileges="SELECT on V_$PARAMETER, V_$SPPARAMETER",
                    sql="""SELECT name, value
FROM   v$parameter
WHERE  name = 'spfile';

SELECT
       sid,
       name,
       display_value,
       ordinal,
       specified
FROM   v$spparameter
WHERE  specified = 'TRUE'
ORDER BY name, sid, ordinal;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="19_control_files.sql",
            category="01_Basic",
            purpose="List control file multiplexed copies and status",
            difficulty="Basic",
            production_use="YES",
            description="""Production databases must multiplex control files on independent
failure groups or disks. A single control file is a single point of failure.""",
            queries=[
                Query(
                    title="Control file locations and status",
                    what="Reads V$CONTROLFILE for name, status, and is_recovery_dest_file.",
                    columns="NAME, STATUS, IS_RECOVERY_DEST_FILE, BLOCK_SIZE, FILE_SIZE_BLKS.",
                    interpret="STATUS NULL is healthy. STATUS INVALID means that copy is unusable.",
                    problem="Only one control file. A copy on the same ASM diskgroup as the only other copy with NORMAL redundancy still shares some risk if the diskgroup is lost.",
                    action="Add a multiplexed copy on a separate diskgroup. Do not move control files without a change window and backup.",
                    caution="Safe. Do not ALTER DATABASE BACKUP CONTROLFILE or RENAME here.",
                    privileges="SELECT on V_$CONTROLFILE, V_$PARAMETER",
                    sql="""SELECT
       status,
       name,
       is_recovery_dest_file,
       block_size,
       file_size_blks
FROM   v$controlfile
ORDER BY name;

SELECT name, value
FROM   v$parameter
WHERE  name = 'control_files';""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="20_redo_log_files.sql",
            category="01_Basic",
            purpose="List redo log groups, members, size, and status",
            difficulty="Basic",
            production_use="YES",
            description="""Shows online redo configuration. Undersized or non-multiplexed redo
causes excessive log switches and single points of failure.
See also 12_Redo_Archive for rate and contention analysis.""",
            queries=[
                Query(
                    title="Redo groups and members",
                    what="Joins V$LOG and V$LOGFILE for group, thread, size, members, and status.",
                    columns="GROUP#, THREAD#, SEQUENCE#, BYTES, MEMBERS, STATUS, MEMBER, TYPE.",
                    interpret="STATUS CURRENT is the active group. INACTIVE can be checkpointed. Only one CURRENT per thread.",
                    problem="Single member per group. Groups smaller than the redo generation of a few minutes. STATUS STALE or INVALID member.",
                    action="Add members on independent disks. Resize redo only during a change window. Never drop the CURRENT group.",
                    caution="Safe. Redo resize is disruptive and is not performed here.",
                    privileges="SELECT on V_$LOG, V_$LOGFILE",
                    sql="""SELECT
       l.group#,
       l.thread#,
       l.sequence#,
       ROUND(l.bytes / 1024 / 1024) AS size_mb,
       l.members,
       l.archived,
       l.status,
       l.first_time
FROM   v$log l
ORDER BY l.thread#, l.group#;

SELECT
       group#,
       status,
       type,
       member,
       is_recovery_dest_file
FROM   v$logfile
ORDER BY group#, member;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="21_archive_log_mode.sql",
            category="01_Basic",
            purpose="Confirm ARCHIVELOG mode and current archive destinations",
            difficulty="Basic",
            production_use="YES",
            description="""Production and any database that requires point-in-time recovery
must run in ARCHIVELOG mode. This script confirms mode and dest status.""",
            queries=[
                Query(
                    title="Log mode and archive destinations",
                    what="Reads V$DATABASE.LOG_MODE and V$ARCHIVE_DEST_STATUS.",
                    columns="LOG_MODE, DEST_ID, DESTINATION, STATUS, ERROR, TYPE.",
                    interpret="ARCHIVELOG is required for RMAN online backups and Data Guard. Dest STATUS ERROR needs immediate attention.",
                    problem="NOARCHIVELOG on production. Dest VALID but ERROR populated. Local dest FULL.",
                    action="If dest is full, free space or add dest. Enabling ARCHIVELOG requires a bounce in MOUNT — change window only.",
                    caution="Safe. Do not ALTER DATABASE ARCHIVELOG from this script.",
                    privileges="SELECT on V_$DATABASE, V_$ARCHIVE_DEST_STATUS",
                    sql="""SELECT name, log_mode, force_logging FROM v$database;

SELECT
       dest_id,
       dest_name,
       status,
       type,
       database_mode,
       recovery_mode,
       destination,
       error,
       gap_status
FROM   v$archive_dest_status
WHERE  status <> 'INACTIVE'
ORDER BY dest_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="22_database_size.sql",
            category="01_Basic",
            purpose="Compute total allocated and used database size",
            difficulty="Basic",
            production_use="YES",
            description="""Gives a capacity snapshot: datafile, tempfile, redo, and control file
sizes. Use for clone sizing and storage requests.""",
            queries=[
                Query(
                    title="Allocated size by file type",
                    what="Sums DBA_DATA_FILES, DBA_TEMP_FILES, V$LOG, and V$CONTROLFILE.",
                    columns="FILE_TYPE, ALLOCATED_GB, USED_GB (datafiles only).",
                    interpret="Allocated is what storage sees. Used is segment occupancy and can be much lower if files are oversized.",
                    problem="Allocated size approaching the ASM diskgroup or volume limit.",
                    action="Plan datafile adds or diskgroup growth. Do not shrink datafiles as a first response.",
                    caution="Safe but queries DBA views. On very large estates this is still cheap.",
                    privileges="SELECT on DBA_DATA_FILES, DBA_TEMP_FILES, DBA_SEGMENTS, V_$LOG, V_$CONTROLFILE",
                    sql="""SELECT
       'DATAFILES' AS file_type,
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) AS allocated_gb
FROM   dba_data_files
UNION ALL
SELECT 'TEMPFILES',
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2)
FROM   dba_temp_files
UNION ALL
SELECT 'REDO',
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2)
FROM   v$log
UNION ALL
SELECT 'CONTROLFILE',
       ROUND(SUM(block_size * file_size_blks) / 1024 / 1024 / 1024, 2)
FROM   v$controlfile;

SELECT ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) AS segment_used_gb
FROM   dba_segments;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="23_schema_size.sql",
            category="01_Basic",
            purpose="Show segment size by schema owner",
            difficulty="Basic",
            production_use="YES",
            description="""Ranks schemas by space. On EBS, APPS is a synonym owner — most
space sits in product schemas (GL, AR, INV, XX custom, etc.).""",
            queries=[
                Query(
                    title="Schema size ranking",
                    what="Aggregates DBA_SEGMENTS by owner.",
                    columns="OWNER, SEGMENT_COUNT, SIZE_GB.",
                    interpret="Sudden growth in one owner usually means a large interface table, audit table, or missing purge.",
                    problem="A custom XX schema or FND/WF table growing faster than the daily baseline.",
                    action="Drill into 05_Objects / EBS growth scripts for that owner. Do not resize tablespaces until you know which segment grew.",
                    caution="Safe. DBA_SEGMENTS is a dictionary view; may take a few seconds on large EBS databases.",
                    privileges="SELECT on DBA_SEGMENTS",
                    ebs="Useful for EBS",
                    sql="""SELECT
       owner,
       COUNT(*) AS segment_count,
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) AS size_gb
FROM   dba_segments
GROUP BY owner
ORDER BY SUM(bytes) DESC;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="24_tablespace_size.sql",
            category="01_Basic",
            purpose="Show tablespace allocated, used, and free space with warning levels",
            difficulty="Basic",
            production_use="YES",
            description="""Daily capacity check. Warning bands:
  < 70% used  = Normal
  70-85%      = Monitor
  85-95%      = Warning
  > 95%       = Critical
Autoextend can hide 'full' until MAXSIZE is reached — see 04_Tablespaces_Datafiles.""",
            queries=[
                Query(
                    title="Tablespace usage with alert bands",
                    what="Joins DBA_TABLESPACES, DBA_DATA_FILES, and DBA_FREE_SPACE for used percent.",
                    columns="TABLESPACE_NAME, ALLOC_GB, USED_GB, FREE_GB, USED_PCT, ALERT_LEVEL.",
                    interpret="USED_PCT is against current allocated size, not MAXSIZE. A 90% file that can autoextend is less urgent than a 90% file at MAXSIZE.",
                    problem="CRITICAL (>95%) on SYSTEM, SYSAUX, UNDO, or a tablespace an EBS product needs tonight.",
                    action="Add a datafile or raise MAXSIZE. Investigate unexpected growth before blindly adding space.",
                    caution="Safe. Does not include TEMP — use 14_TEMP. Dictionary query; slight cost on huge databases.",
                    privileges="SELECT on DBA_TABLESPACES, DBA_DATA_FILES, DBA_FREE_SPACE",
                    sql="""WITH alloc AS (
       SELECT tablespace_name,
              SUM(bytes) AS alloc_bytes,
              SUM(DECODE(autoextensible, 'YES', maxbytes, bytes)) AS max_bytes
       FROM   dba_data_files
       GROUP BY tablespace_name
),
free AS (
       SELECT tablespace_name,
              SUM(bytes) AS free_bytes
       FROM   dba_free_space
       GROUP BY tablespace_name
)
SELECT
       ts.tablespace_name,
       ts.status,
       ts.contents,
       ROUND(a.alloc_bytes / 1024 / 1024 / 1024, 2) AS alloc_gb,
       ROUND((a.alloc_bytes - NVL(f.free_bytes, 0)) / 1024 / 1024 / 1024, 2) AS used_gb,
       ROUND(NVL(f.free_bytes, 0) / 1024 / 1024 / 1024, 2) AS free_gb,
       ROUND(a.max_bytes / 1024 / 1024 / 1024, 2) AS max_gb,
       ROUND((a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes, 1) AS used_pct,
       CASE
         WHEN (a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes > 95 THEN 'CRITICAL'
         WHEN (a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes > 85 THEN 'WARNING'
         WHEN (a.alloc_bytes - NVL(f.free_bytes, 0)) * 100 / a.alloc_bytes > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_tablespaces ts
JOIN   alloc a ON a.tablespace_name = ts.tablespace_name
LEFT JOIN free f ON f.tablespace_name = ts.tablespace_name
WHERE  ts.contents = 'PERMANENT'
ORDER BY used_pct DESC;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="25_datafile_information.sql",
            category="01_Basic",
            purpose="List datafiles with size, autoextend, and status",
            difficulty="Basic",
            production_use="YES",
            description="""File-level view for space and backup planning. ONLINE / RECOVER
status problems are restore incidents.""",
            queries=[
                Query(
                    title="Datafile inventory",
                    what="Reads DBA_DATA_FILES and V$DATAFILE for status and checkpoint.",
                    columns="FILE_ID, FILE_NAME, TABLESPACE_NAME, SIZE_GB, AUTOEXTENSIBLE, MAX_GB, STATUS.",
                    interpret="AVAILABLE is healthy. RECOVER means the file needs media recovery. ONLINE in DBA_DATA_FILES plus SYSOFF in V$DATAFILE is a problem.",
                    problem="File at MAXSIZE and tablespace nearly full. STATUS RECOVER. File on a full ASM diskgroup.",
                    action="Add space or recover the file with RMAN. Do not resize below HWM.",
                    caution="Safe. Adding datafiles is a change.",
                    privileges="SELECT on DBA_DATA_FILES, V_$DATAFILE",
                    sql="""SELECT
       df.file_id,
       df.tablespace_name,
       df.file_name,
       ROUND(df.bytes / 1024 / 1024 / 1024, 2) AS size_gb,
       df.autoextensible,
       ROUND(df.maxbytes / 1024 / 1024 / 1024, 2) AS max_gb,
       df.status,
       df.online_status,
       v.status AS v_status
FROM   dba_data_files df
JOIN   v$datafile v ON v.file# = df.file_id
ORDER BY df.tablespace_name, df.file_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="26_tempfile_information.sql",
            category="01_Basic",
            purpose="List tempfiles and temporary tablespace configuration",
            difficulty="Basic",
            production_use="YES",
            description="""Temporary tablespaces are instance-local on RAC (each instance has
tempfiles). Running out of TEMP raises ORA-01652 during sorts and hash joins.""",
            queries=[
                Query(
                    title="Tempfile inventory",
                    what="Lists DBA_TEMP_FILES and default temporary tablespace.",
                    columns="FILE_NAME, TABLESPACE_NAME, SIZE_GB, AUTOEXTENSIBLE, MAX_GB.",
                    interpret="TEMP can look 'full' after a large sort and then shrink in 12c+ if it is a locally managed tempfile that shrinks — but space is reused without shrinking.",
                    problem="Single small tempfile, autoextend NO, during month-end or Gather Schema Stats.",
                    action="Add a tempfile or enable autoextend with a sane MAXSIZE. See 14_TEMP for session-level usage.",
                    caution="Safe. Shrinking TEMP can be done online but is a change.",
                    privileges="SELECT on DBA_TEMP_FILES, DATABASE_PROPERTIES",
                    sql="""SELECT property_name, property_value
FROM   database_properties
WHERE  property_name = 'DEFAULT_TEMP_TABLESPACE';

SELECT
       file_id,
       tablespace_name,
       file_name,
       ROUND(bytes / 1024 / 1024 / 1024, 2) AS size_gb,
       autoextensible,
       ROUND(maxbytes / 1024 / 1024 / 1024, 2) AS max_gb,
       status
FROM   dba_temp_files
ORDER BY tablespace_name, file_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="27_undo_information.sql",
            category="01_Basic",
            purpose="Show undo tablespace, retention, and basic usage",
            difficulty="Basic",
            production_use="YES",
            description="""Quick undo health. Deep ORA-01555 / ORA-30036 analysis is in 13_UNDO.""",
            queries=[
                Query(
                    title="Undo configuration and usage",
                    what="Shows undo_tablespace, undo_retention, and DBA_UNDO_EXTENTS summary.",
                    columns="UNDO_TABLESPACE, UNDO_RETENTION, STATUS extents, TUNED_UNDORETENTION.",
                    interpret="ACTIVE extents are in-use by transactions. UNEXPIRED are retained for consistent read. EXPIRED can be reused.",
                    problem="No EXPIRED space and UNEXPIRED being stolen — risk of ORA-01555. Undo tablespace 95%+ used.",
                    action="Increase undo tablespace or undo_retention only after checking long-running transactions.",
                    caution="Safe. Changing undo_retention affects flashback query and EBS long reports.",
                    privileges="SELECT on V_$PARAMETER, V_$UNDOSTAT, DBA_UNDO_EXTENTS, DBA_TABLESPACES",
                    sql="""SELECT name, value
FROM   v$parameter
WHERE  name IN ('undo_tablespace','undo_management','undo_retention');

SELECT
       tablespace_name,
       status,
       COUNT(*) AS extents,
       ROUND(SUM(bytes) / 1024 / 1024, 1) AS mb
FROM   dba_undo_extents
GROUP BY tablespace_name, status
ORDER BY tablespace_name, status;

SELECT
       TO_CHAR(begin_time, 'DD-MON-RR HH24:MI') AS begin_time,
       undoblks,
       txncount,
       maxquerylen,
       maxqueryid,
       tuned_undoretention,
       ssolderrcnt,
       nospaceerrcnt
FROM   v$undostat
WHERE  begin_time > SYSDATE - 1 / 24
ORDER BY begin_time DESC;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="28_invalid_objects.sql",
            category="01_Basic",
            purpose="List invalid objects by owner",
            difficulty="Basic",
            production_use="YES",
            description="""Invalid packages, views, and synonyms break EBS concurrent programs
and Forms. After patching, expect some invalids — they should compile
cleanly with utlrp / adop compile.""",
            queries=[
                Query(
                    title="Invalid objects summary and detail",
                    what="Reads DBA_OBJECTS where STATUS = INVALID.",
                    columns="OWNER, OBJECT_TYPE, OBJECT_NAME, LAST_DDL_TIME.",
                    interpret="A few invalids in unused schemas may be ignorable. Invalids in APPS, GL, or XX custom code are not.",
                    problem="Sudden jump after a patch or import. SYS/SYSTEM invalids after a failed RU.",
                    action="Compile with utlrp.sql (SYS) or adodfcmp / adop compile for EBS. Do not compile SYS objects ad hoc during production hours without a plan.",
                    caution="Safe to query. Compiling APPS packages can invalidate dependents and lock objects — do that in a window.",
                    privileges="SELECT on DBA_OBJECTS",
                    ebs="Useful for EBS",
                    sql="""SELECT owner, object_type, COUNT(*) AS invalid_count
FROM   dba_objects
WHERE  status = 'INVALID'
GROUP BY owner, object_type
ORDER BY invalid_count DESC, owner, object_type;

SELECT
       owner,
       object_type,
       object_name,
       last_ddl_time
FROM   dba_objects
WHERE  status = 'INVALID'
ORDER BY owner, object_type, object_name;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="29_objects_by_owner.sql",
            category="01_Basic",
            purpose="Count objects by owner and type",
            difficulty="Basic",
            production_use="YES",
            description="""Inventory used to compare a clone to production and to find unexpected
object types (for example a user creating tables in APPS).""",
            queries=[
                Query(
                    title="Object counts by owner and type",
                    what="Aggregates DBA_OBJECTS.",
                    columns="OWNER, OBJECT_TYPE, OBJECT_COUNT.",
                    interpret="EBS has a well-known shape: many synonyms in APPS, tables in product schemas.",
                    problem="Application user owning tables in SYSTEM or SYSAUX. Sudden new object type counts after a failed clone.",
                    action="Investigate unexpected owners. Do not drop objects from this script.",
                    caution="Safe. Can be large on EBS — summary query is cheap.",
                    privileges="SELECT on DBA_OBJECTS",
                    ebs="Useful for EBS",
                    sql="""SELECT
       owner,
       object_type,
       COUNT(*) AS object_count
FROM   dba_objects
WHERE  owner NOT IN ('SYS','SYSTEM','XDB','MDSYS','CTXSYS','WMSYS','ORDDATA','ORDSYS')
GROUP BY owner, object_type
ORDER BY owner, object_type;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="30_database_components.sql",
            category="01_Basic",
            purpose="List installed database components and versions",
            difficulty="Basic",
            production_use="YES",
            description="""DBA_REGISTRY shows components (CATALOG, CATPROC, JAVAVM, XML, OLS, etc.)
and whether they are VALID after a patch.""",
            queries=[
                Query(
                    title="Registry components",
                    what="Reads DBA_REGISTRY for component status.",
                    columns="COMP_ID, COMP_NAME, VERSION, STATUS, MODIFIED.",
                    interpret="STATUS VALID is required after datapatch. OPTION OFF is not the same as INVALID.",
                    problem="STATUS INVALID or LOADING after a failed datapatch / RU.",
                    action="Rerun datapatch from the new home. Collect DBA_REGISTRY_SQLPATCH. Do not compile catalog objects randomly.",
                    caution="Safe. datapatch is a maintenance action.",
                    privileges="SELECT on DBA_REGISTRY",
                    sql="""SELECT
       comp_id,
       comp_name,
       version,
       status,
       modified,
       schema
FROM   dba_registry
ORDER BY comp_id;""",
                )
            ],
        ),
        Script(
            folder="01_Basic",
            file_name="31_registry_information.sql",
            category="01_Basic",
            purpose="Show datapatch / SQL patch registry history",
            difficulty="Basic",
            production_use="YES",
            description="""DBA_REGISTRY_SQLPATCH (12.1.0.2+) is the source of truth for RU/RUR
and one-off SQL patches applied by datapatch.""",
            queries=[
                Query(
                    title="SQL patch registry",
                    what="Lists applied and failed SQL patches with action time.",
                    columns="PATCH_ID, VERSION, STATUS, ACTION, DESCRIPTION, ACTION_TIME.",
                    interpret="STATUS SUCCESS is healthy. WITH ERRORS means datapatch did not finish — the binary may be patched but SQL is not.",
                    problem="A recent RU with STATUS WITH ERRORS or APPLY not present after a patch window.",
                    action="Review $ORACLE_HOME/cfgtoollogs/sqlpatch. Rerun datapatch. Do not open the app if SQL patch is incomplete.",
                    caution="Safe. Requires 12.1.0.2+ views (present on 19c).",
                    privileges="SELECT on DBA_REGISTRY_SQLPATCH",
                    notes="Oracle 19c (DBA_REGISTRY_SQLPATCH).",
                    sql="""SELECT
       patch_id,
       patch_uid,
       version,
       status,
       action,
       description,
       action_time,
       source_version,
       source_build_description
FROM   dba_registry_sqlpatch
ORDER BY action_time DESC;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
