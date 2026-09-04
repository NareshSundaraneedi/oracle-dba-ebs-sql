# SQL Toolkit Master Index

Total scripts: **472**  
Oracle: **19c** · EBS: **R12.2.x** · RAC / ASM / Data Guard scripts are included and no-op safely when those features are absent.

File naming: `NN_short_snake_case.sql` inside each category folder.

## 01_Basic

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_database_name.sql` | Identify the current database name and unique name | Basic | YES | R12.2 |
| `02_dbid.sql` | Display DBID used by RMAN, AWR, and Data Guard | Basic | YES | R12.2 |
| `03_instance_name.sql` | Show instance name, number, and thread | Basic | YES | R12.2 |
| `04_host_name.sql` | Identify the database server host for the current instance | Basic | YES | R12.2 |
| `05_database_version.sql` | Show Oracle database version, RU, and compatible setting | Basic | YES | R12.2 |
| `06_oracle_home.sql` | Locate ORACLE_HOME and ORACLE_BASE used by the instance | Basic | YES | R12.2 |
| `07_startup_time.sql` | Show instance startup time | Basic | YES | R12.2 |
| `08_database_uptime.sql` | Calculate instance uptime in days, hours, and minutes | Basic | YES | R12.2 |
| `09_database_role.sql` | Show primary / standby / snapshot standby role | Basic | YES | R12.2 |
| `10_open_mode.sql` | Show database and PDB open mode | Basic | YES | R12.2 |
| `11_database_status.sql` | High-level database health: role, mode, log mode, force logging | Basic | YES | R12.2 |
| `12_instance_status.sql` | Show instance status, logins, and archiver health | Basic | YES | R12.2 |
| `13_rac_status.sql` | Determine whether the database is RAC and list instances | Basic | YES | R12.2 |
| `14_server_information.sql` | CPU, platform, and instance resource snapshot | Basic | YES | R12.2 |
| `15_character_set.sql` | Show database and national character sets | Basic | YES | R12.2 |
| `16_nls_parameters.sql` | Compare database, instance, and session NLS settings | Basic | YES | R12.2 |
| `17_database_parameters.sql` | List non-default initialization parameters | Basic | YES | R12.2 |
| `18_spfile_location.sql` | Locate the SPFILE the instance is using | Basic | YES | R12.2 |
| `19_control_files.sql` | List control file multiplexed copies and status | Basic | YES | R12.2 |
| `20_redo_log_files.sql` | List redo log groups, members, size, and status | Basic | YES | R12.2 |
| `21_archive_log_mode.sql` | Confirm ARCHIVELOG mode and current archive destinations | Basic | YES | R12.2 |
| `22_database_size.sql` | Compute total allocated and used database size | Basic | YES | R12.2 |
| `23_schema_size.sql` | Show segment size by schema owner | Basic | YES | R12.2 |
| `24_tablespace_size.sql` | Show tablespace allocated, used, and free space with warning levels | Basic | YES | R12.2 |
| `25_datafile_information.sql` | List datafiles with size, autoextend, and status | Basic | YES | R12.2 |
| `26_tempfile_information.sql` | List tempfiles and temporary tablespace configuration | Basic | YES | R12.2 |
| `27_undo_information.sql` | Show undo tablespace, retention, and basic usage | Basic | YES | R12.2 |
| `28_invalid_objects.sql` | List invalid objects by owner | Basic | YES | R12.2 |
| `29_objects_by_owner.sql` | Count objects by owner and type | Basic | YES | R12.2 |
| `30_database_components.sql` | List installed database components and versions | Basic | YES | R12.2 |
| `31_registry_information.sql` | Show datapatch / SQL patch registry history | Basic | YES | R12.2 |
## 02_Database_Administration

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_database_properties.sql` | List DATABASE_PROPERTIES including default tablespaces and character set | Basic | YES | R12.2 |
| `02_instance_parameters.sql` | Show all initialization parameters with session/system modify flags | Intermediate | YES | R12.2 |
| `03_hidden_parameters.sql` | List underscore parameters that have been explicitly set | Advanced | YES | R12.2 |
| `04_pdb_information.sql` | List pluggable databases, open mode, and recovery status | Intermediate | YES | R12.2 |
| `05_cdb_information.sql` | Show CDB vs non-CDB and container context | Basic | YES | R12.2 |
| `06_alert_log_location.sql` | Locate the ADR alert log XML and text files | Basic | YES | R12.2 |
| `07_diagnostic_dest.sql` | Show diagnostic_dest and ADR size pressure | Intermediate | YES | R12.2 |
| `08_fra_usage.sql` | Fast Recovery Area usage and reclaimable space | Intermediate | YES | R12.2 |
| `09_recyclebin.sql` | Show recyclebin contents and space they occupy | Intermediate | YES | R12.2 |
| `10_database_links.sql` | Inventory database links | Intermediate | YES | R12.2 |
| `11_directories.sql` | List Oracle directory objects and who can write them | Intermediate | YES | R12.2 |
| `12_jobs_scheduler.sql` | List DBMS_SCHEDULER jobs and DBMS_JOB leftovers | Intermediate | YES | R12.2 |
| `13_resource_limits.sql` | Compare processes/sessions usage against initialization limits | Intermediate | YES | R12.2 |
| `14_feature_usage.sql` | Show DBA_FEATURE_USAGE_STATISTICS for licensing awareness | Advanced | YES | R12.2 |
| `15_patch_registry.sql` | Combine SQL patch registry with opatch-equivalent inventory in-db | Intermediate | YES | R12.2 |
| `16_option_status.sql` | Show installed Oracle options (RAC, Partitioning, etc.) | Basic | YES | R12.2 |
## 03_Users_Security

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_list_users.sql` | List all database users with default tablespace and profile | Basic | YES | R12.2 |
| `02_user_status.sql` | Count users by account status | Basic | YES | R12.2 |
| `03_locked_users.sql` | List locked accounts and lock dates | Basic | YES | R12.2 |
| `04_expired_users.sql` | List expired and expired-grace accounts | Basic | YES | R12.2 |
| `05_password_expiry.sql` | Forecast password expiry for OPEN accounts | Intermediate | YES | R12.2 |
| `06_profile_information.sql` | List profiles and resource/password limits | Intermediate | YES | R12.2 |
| `07_user_creation_date.sql` | Show recently created database users | Basic | YES | R12.2 |
| `08_last_login.sql` | Show last login time (12c+ DBA_USERS.LAST_LOGIN) | Intermediate | YES | R12.2 |
| `09_default_tablespace.sql` | Find users whose default tablespace is SYSTEM or SYSAUX | Basic | YES | R12.2 |
| `10_temporary_tablespace.sql` | Show temporary tablespace assigned to each user | Basic | YES | R12.2 |
| `11_roles.sql` | List roles and role grants to users | Intermediate | YES | R12.2 |
| `12_system_privileges.sql` | List powerful system privileges | Intermediate | YES | R12.2 |
| `13_object_privileges.sql` | List object grants for a schema or grantee | Intermediate | YES | R12.2 |
| `14_role_privileges.sql` | Expand privileges a role conveys | Intermediate | YES | R12.2 |
| `15_grants.sql` | Show all privilege paths for one user (roles + direct grants) | Intermediate | YES | R12.2 |
| `16_proxy_users.sql` | List proxy user relationships | Intermediate | YES | R12.2 |
| `17_failed_logins.sql` | Investigate failed logins from unified audit or DBA_USERS lock state | Advanced | YES | R12.2 |
| `18_password_policies.sql` | Extract password-related profile limits | Intermediate | YES | R12.2 |
| `19_privilege_analysis.sql` | Show privilege analysis captures (12c+ Privilege Analysis) | Advanced | YES | R12.2 |
| `20_security_checks.sql` | Packaged security hygiene checks for a production database | Advanced | YES | R12.2 |
## 04_Tablespaces_Datafiles

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_tablespace_usage.sql` | Tablespace used percent with 70/85/95 alert bands including autoextend headroom | Intermediate | YES | R12.2 |
| `02_tablespace_free_space.sql` | Show free space chunks (fragmentation-aware) | Intermediate | YES | R12.2 |
| `03_tablespace_growth.sql` | Estimate tablespace growth from AWR or DBA_HIST_TBSPC_SPACE_USAGE | Advanced | YES | R12.2 |
| `04_datafile_usage.sql` | Per-datafile allocated size and autoextend remaining | Intermediate | YES | R12.2 |
| `05_autoextend_status.sql` | List files with autoextend off or unlimited maxsize | Basic | YES | R12.2 |
| `06_maximum_datafile_size.sql` | Explain smallfile vs bigfile maximum sizes | Intermediate | YES | R12.2 |
| `07_datafile_growth.sql` | Show files that autoextended recently via alert or file size vs creation | Advanced | YES | R12.2 |
| `08_bigfile_tablespaces.sql` | List bigfile tablespaces and their single datafile | Basic | YES | R12.2 |
| `09_temp_tablespace_usage.sql` | Temporary tablespace usage (summary) | Intermediate | YES | R12.2 |
| `10_temp_usage_by_session.sql` | TEMP consumption by session (pointer to 14_TEMP) | Intermediate | YES | R12.2 |
| `11_undo_usage.sql` | Undo tablespace usage snapshot (storage view) | Intermediate | YES | R12.2 |
| `12_undo_retention.sql` | Show undo_retention vs tuned retention | Intermediate | YES | R12.2 |
| `13_segment_growth.sql` | Largest recent segment growth using DBA_HIST_SEG_STAT (AWR) | Advanced | YES | R12.2 |
| `14_largest_segments.sql` | Top segments by size right now | Basic | YES | R12.2 |
| `15_largest_tables.sql` | Largest tables (excludes indexes and undo) | Basic | YES | R12.2 |
| `16_largest_indexes.sql` | Largest indexes | Basic | YES | R12.2 |
| `17_free_space_fragmentation.sql` | Detect free space fragmentation that can block extents | Advanced | YES | R12.2 |
| `18_asm_diskgroup_usage.sql` | ASM diskgroup free space from the RDBMS instance | Intermediate | YES | R12.2 |
## 05_Objects

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_invalid_objects.sql` | Invalid objects with dependency hints | Intermediate | YES | R12.2 |
| `02_objects_by_owner.sql` | Object inventory for one owner | Basic | YES | R12.2 |
| `03_object_counts.sql` | Database-wide object counts excluding Oracle-maintained schemas | Basic | YES | R12.2 |
| `04_tables_without_indexes.sql` | Find sizable tables that have no indexes at all | Intermediate | YES | R12.2 |
| `05_unusable_indexes.sql` | List UNUSABLE indexes and partitions | Intermediate | YES | R12.2 |
| `06_disabled_constraints.sql` | List disabled constraints | Intermediate | YES | R12.2 |
| `07_foreign_keys.sql` | Find foreign keys without supporting indexes (parent update / child delete risk) | Advanced | YES | R12.2 |
| `08_triggers.sql` | List enabled triggers (performance and mutating-table suspects) | Intermediate | YES | R12.2 |
| `09_synonyms.sql` | Find invalid or cross-schema synonyms | Intermediate | YES | R12.2 |
| `10_views.sql` | List invalid views and view dependency counts | Intermediate | YES | R12.2 |
| `11_sequences.sql` | Sequences near MAXVALUE or with odd cache settings | Intermediate | YES | R12.2 |
| `12_materialized_views.sql` | MV freshness, compile state, and last refresh | Intermediate | YES | R12.2 |
| `13_dependencies.sql` | Show dependencies for one object | Intermediate | YES | R12.2 |
| `14_object_modifications.sql` | Objects with recent LAST_DDL_TIME | Intermediate | YES | R12.2 |
| `15_compile_invalid_objects.sql` | Guided compile approach (utlrp / DBMS_UTILITY) without auto-executing | Advanced | YES | R12.2 |
## 06_Sessions_Processes

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_all_sessions.sql` | List all sessions with instance, user, program, and status | Basic | YES | R12.2 |
| `02_active_sessions.sql` | Sessions currently ACTIVE (on CPU or waiting) | Basic | YES | R12.2 |
| `03_inactive_sessions.sql` | INACTIVE sessions and how long they have been idle | Basic | YES | R12.2 |
| `04_long_running_sessions.sql` | Active sessions with LAST_CALL_ET over a threshold | Intermediate | YES | R12.2 |
| `05_sessions_by_user.sql` | Session counts grouped by database username | Basic | YES | R12.2 |
| `06_sessions_by_machine.sql` | Session counts by client machine | Basic | YES | R12.2 |
| `07_sessions_by_program.sql` | Session counts by PROGRAM | Basic | YES | R12.2 |
| `08_sessions_by_module.sql` | Session counts by MODULE / ACTION (EBS instrumentation) | Intermediate | YES | R12.2 |
| `09_sessions_by_service.sql` | Session counts by SERVICE_NAME | Intermediate | YES | R12.2 |
| `10_sessions_by_sql_id.sql` | Which SQL_IDs are being executed right now | Intermediate | YES | R12.2 |
| `11_sessions_consuming_cpu.sql` | Sessions with highest recent CPU from V$SESSTAT / ASH | Advanced | YES | R12.2 |
| `12_sessions_consuming_pga.sql` | Top PGA consumers among current sessions | Intermediate | YES | R12.2 |
| `13_sessions_generating_io.sql` | Sessions with high physical reads/writes | Advanced | YES | R12.2 |
| `14_sessions_waiting.sql` | Active sessions currently waiting (non-idle) | Intermediate | YES | R12.2 |
| `15_sessions_waiting_on_locks.sql` | Sessions waiting on enqueue / TX / TM locks | Intermediate | YES | R12.2 |
| `16_generate_kill_session.sql` | Generate ALTER SYSTEM KILL SESSION commands (does not execute them) | Intermediate | YES | R12.2 |
| `17_generate_disconnect_session.sql` | Generate ALTER SYSTEM DISCONNECT SESSION ... POST_TRANSACTION commands | Intermediate | YES | R12.2 |
| `18_process_usage.sql` | OS process list as seen by Oracle (V$PROCESS) | Intermediate | YES | R12.2 |
| `19_session_process_utilization.sql` | Utilization of processes/sessions parameters with headroom alerts | Intermediate | YES | R12.2 |
## 07_Performance_Tuning

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_top_sql_elapsed.sql` | Top SQL by cumulative elapsed time in the cursor cache | Intermediate | YES | R12.2 |
| `02_top_sql_cpu.sql` | Top SQL by cumulative CPU time in the cursor cache | Intermediate | YES | R12.2 |
| `03_top_sql_buffer_gets.sql` | Top SQL by buffer gets (logical I/O) | Intermediate | YES | R12.2 |
| `04_top_sql_physical_reads.sql` | Top SQL by physical reads (disk I/O) | Intermediate | YES | R12.2 |
| `05_top_sql_executions.sql` | Top SQL by execution count | Intermediate | YES | R12.2 |
| `06_top_sql_rows_processed.sql` | Top SQL by rows processed | Intermediate | YES | R12.2 |
| `07_sql_high_elapsed.sql` | SQL with high elapsed per execution (long runners, not just popular) | Intermediate | YES | R12.2 |
| `08_sql_high_cpu.sql` | SQL with high CPU per execution | Intermediate | YES | R12.2 |
| `09_sql_high_io.sql` | SQL with high physical I/O per execution | Intermediate | YES | R12.2 |
| `10_sql_excessive_executions.sql` | Very chatty SQL (high executions, not necessarily high elapsed) | Intermediate | YES | R12.2 |
| `11_sql_poor_efficiency.sql` | SQL with terrible buffer gets per row (inefficient access) | Advanced | YES | R12.2 |
| `12_sql_plan_changes.sql` | SQL_IDs that currently have more than one plan hash in cache | Advanced | YES | R12.2 |
| `13_sql_plan_history.sql` | Plan history for one SQL_ID from AWR (DBA_HIST_SQLSTAT) | Advanced | YES | R12.2 |
| `14_sql_plan_regressions.sql` | Detect SQL_IDs whose elapsed/exec worsened across plans in AWR | Advanced | YES | R12.2 |
| `15_sql_child_cursors.sql` | Child cursor explosion and reason codes | Advanced | YES | R12.2 |
| `16_bind_variables.sql` | Inspect bind values captured for a SQL_ID | Advanced | YES | R12.2 |
| `17_hard_parsing.sql` | Hard parse rate from V$SYSSTAT | Advanced | YES | R12.2 |
| `18_soft_parsing.sql` | Soft parse vs execute ratio | Advanced | YES | R12.2 |
| `19_parse_ratio.sql` | Human-readable parse ratios with alert bands | Intermediate | YES | R12.2 |
| `20_library_cache.sql` | Library cache hit ratios and lock/pin counts | Advanced | YES | R12.2 |
| `21_shared_pool.sql` | Shared pool free memory, advice, and reserved list | Advanced | YES | R12.2 |
| `22_cursor_usage.sql` | Open cursors per session vs open_cursors parameter | Intermediate | YES | R12.2 |
| `23_invalidations.sql` | Cursor invalidations and recent DDL that may have caused them | Advanced | YES | R12.2 |
| `24_full_table_scans.sql` | SQL currently doing or recently doing full table scans | Advanced | YES | R12.2 |
| `25_index_usage.sql` | Index usage from DBA_INDEX_USAGE (12.2+) or monitoring | Advanced | YES | R12.2 |
| `26_missing_indexes.sql` | Heuristic missing-index suspects (unindexed FK + FTS), not a magic advisor | Advanced | YES | R12.2 |
| `27_unused_indexes.sql` | Indexes with no usage tracking hits (candidates only) | Advanced | YES | R12.2 |
| `28_statistics_status.sql` | Stats freshness summary by schema | Intermediate | YES | R12.2 |
| `29_stale_statistics.sql` | Objects marked stale in DBA_TAB_STATISTICS | Intermediate | YES | R12.2 |
| `30_optimizer_statistics.sql` | Optimizer-related parameters and stats job status | Advanced | YES | R12.2 |
| `31_histogram_information.sql` | Histograms on columns for a table (skew / bind peeking) | Advanced | YES | R12.2 |
## 08_SQL_Tuning

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_sql_monitor.sql` | Real-Time SQL Monitor status for long-running statements | Advanced | YES | R12.2 |
| `02_execution_plan.sql` | Display the actual cursor plan for a SQL_ID (DBMS_XPLAN) | Intermediate | YES | R12.2 |
| `03_sql_plan_history.sql` | Historical plans from AWR (DISPLAY_AWR) | Advanced | YES | R12.2 |
| `04_sql_tuning_advisor.sql` | How to invoke SQL Tuning Advisor (commands generated, not auto-run) | Advanced | YES | R12.2 |
| `05_sql_profiles.sql` | List existing SQL profiles | Advanced | YES | R12.2 |
| `06_sql_baselines.sql` | List SQL plan baselines (SPM) | Advanced | YES | R12.2 |
| `07_sql_patches.sql` | List SQL patches (hint-based) | Advanced | YES | R12.2 |
| `08_bind_peeking.sql` | Bind peek / adaptive cursor sharing status for a SQL_ID | Advanced | YES | R12.2 |
| `09_adaptive_plans.sql` | Identify adaptive plans in cache | Advanced | YES | R12.2 |
| `10_cardinality_feedback.sql` | Statistics / cardinality feedback usage on cursors | Advanced | YES | R12.2 |
| `11_awr_report_generation.sql` | Generate AWR report (instance or global) — instructions and snapshot IDs | Advanced | YES | R12.2 |
| `12_awr_snapshots.sql` | AWR snapshot inventory and errors | Intermediate | YES | R12.2 |
| `13_snapshot_interval.sql` | AWR retention and interval (DBMS_WORKLOAD_REPOSITORY) | Intermediate | YES | R12.2 |
| `14_top_sql_from_awr.sql` | Top SQL from AWR by elapsed time for a time window | Advanced | YES | R12.2 |
| `15_awr_top_sql_cpu.sql` | Top AWR SQL by CPU for a time window | Advanced | YES | R12.2 |
| `16_awr_top_sql_elapsed.sql` | Alias-style elapsed ranking with per-exec (AWR) | Advanced | YES | R12.2 |
| `17_awr_top_sql_io.sql` | Top AWR SQL by I/O wait and disk reads | Advanced | YES | R12.2 |
| `18_awr_top_wait_events.sql` | Top wait events from AWR for a window | Advanced | YES | R12.2 |
| `19_db_time.sql` | DB time, DB CPU, and background time from AWR / V$SYS_TIME_MODEL | Advanced | YES | R12.2 |
| `20_average_active_sessions.sql` | Average Active Sessions from ASH or estimated from DB time | Advanced | YES | R12.2 |
| `21_ash_analysis.sql` | General ASH breakdown for the last N minutes | Advanced | YES | R12.2 |
| `22_ash_by_sql_id.sql` | ASH filtered to one SQL_ID | Advanced | YES | R12.2 |
| `23_ash_by_session.sql` | ASH for one SID/SERIAL | Advanced | YES | R12.2 |
| `24_ash_by_wait_event.sql` | ASH filtered to one wait event | Advanced | YES | R12.2 |
| `25_ash_by_module.sql` | ASH load by MODULE (EBS form / concurrent program) | Advanced | YES | R12.2 |
| `26_ash_by_machine.sql` | ASH load by client machine | Advanced | YES | R12.2 |
| `27_sql_execution_history.sql` | Historical executions from SQL Monitor and AWR for one SQL_ID | Advanced | YES | R12.2 |
## 09_Wait_Events

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_system_wait_events.sql` | Instance-level wait event totals since startup (non-idle) | Intermediate | YES | R12.2 |
| `02_session_wait_events.sql` | Per-session wait totals (V$SESSION_EVENT) | Intermediate | YES | R12.2 |
| `03_top_wait_events.sql` | Top 20 non-idle wait events with average wait | Basic | YES | R12.2 |
| `04_cpu_vs_wait.sql` | CPU vs wait breakdown from the time model | Intermediate | YES | R12.2 |
| `05_io_waits.sql` | All User I/O and System I/O wait events | Intermediate | YES | R12.2 |
| `06_user_io.sql` | Foreground User I/O only | Intermediate | YES | R12.2 |
| `07_concurrency_waits.sql` | Concurrency wait class (latches, buffers, mutexes) | Advanced | YES | R12.2 |
| `08_commit_waits.sql` | Commit-related waits (log file sync primarily) | Advanced | YES | R12.2 |
| `09_network_waits.sql` | Network wait class (SQL*Net) | Intermediate | YES | R12.2 |
| `10_cluster_waits.sql` | Cluster wait class (RAC global cache) | Advanced | YES | R12.2 |
| `11_rac_waits.sql` | Detailed RAC/global cache wait names | Advanced | YES | R12.2 |
| `12_enqueue_waits.sql` | Enqueue (enq:) waits | Advanced | YES | R12.2 |
| `13_library_cache_waits.sql` | Library cache pin/lock/mutex waits | Advanced | YES | R12.2 |
| `14_buffer_busy_waits.sql` | Buffer busy waits and hot segments | Advanced | YES | R12.2 |
| `15_db_file_sequential_read.sql` | db file sequential read (single-block reads) | Advanced | YES | R12.2 |
| `16_db_file_scattered_read.sql` | db file scattered read (multiblock FTS/index fast full) | Advanced | YES | R12.2 |
| `17_log_file_sync.sql` | log file sync deep dive | Advanced | YES | R12.2 |
| `18_log_file_parallel_write.sql` | log file parallel write (LGWR I/O) | Advanced | YES | R12.2 |
| `19_direct_path_reads.sql` | direct path read / direct path read temp | Advanced | YES | R12.2 |
| `20_direct_path_writes.sql` | direct path write / write temp | Advanced | YES | R12.2 |
## 10_Locks_Blocking

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_blocking_sessions.sql` | List sessions that are blocking others right now | Intermediate | YES | R12.2 |
| `02_blocked_sessions.sql` | List sessions waiting on a blocker | Intermediate | YES | R12.2 |
| `03_blocking_chains.sql` | Assemble blocker→waiter chains including multi-level | Advanced | YES | R12.2 |
| `04_row_locks.sql` | Row-level TX lock waiters (enq: TX - row lock contention) | Advanced | YES | R12.2 |
| `05_tx_locks.sql` | All TX enqueue modes (row lock, ITL, index contention) | Advanced | YES | R12.2 |
| `06_tm_locks.sql` | TM (table) locks — often unindexed FK or explicit LOCK TABLE | Advanced | YES | R12.2 |
| `07_locked_objects.sql` | Objects currently locked (V$LOCKED_OBJECT) | Intermediate | YES | R12.2 |
| `08_sessions_waiting_for_locks.sql` | Waiters only, with object and blocker SQL | Intermediate | YES | R12.2 |
| `09_lock_duration.sql` | How long locks have been held (V$LOCK.CTIME) | Intermediate | YES | R12.2 |
| `10_deadlock_investigation.sql` | Investigate ORA-00060 deadlocks after they occur | Advanced | YES | R12.2 |
| `11_blocking_tree.sql` | Formatted blocking tree for incident bridges | Advanced | YES | R12.2 |
| `12_rac_blocking_sessions.sql` | Cross-instance blocking on RAC (including global locks) | Advanced | YES | R12.2 |
## 11_Memory

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_sga_size.sql` | SGA size vs targets and in-memory use | Basic | YES | R12.2 |
| `02_sga_components.sql` | SGA breakdown by pool | Basic | YES | R12.2 |
| `03_buffer_cache.sql` | Buffer cache size, advice, and hit ratio caveats | Intermediate | YES | R12.2 |
| `04_shared_pool.sql` | Shared pool component detail (memory-focused) | Intermediate | YES | R12.2 |
| `05_large_pool.sql` | Large pool usage (PX, RMAN, UGA shared server) | Intermediate | YES | R12.2 |
| `06_java_pool.sql` | Java pool size — usually small on EBS DB tier | Basic | YES | R12.2 |
| `07_streams_pool.sql` | Streams/GoldenGate pool | Intermediate | YES | R12.2 |
| `08_inmemory_area.sql` | In-Memory column store area (if licensed/enabled) | Advanced | YES | R12.2 |
| `09_pga_target.sql` | PGA targets and limit | Basic | YES | R12.2 |
| `10_pga_usage.sql` | Current PGA aggregate usage vs target | Intermediate | YES | R12.2 |
| `11_pga_by_session.sql` | PGA by session (memory folder copy of session view) | Intermediate | YES | R12.2 |
| `12_top_pga_consumers.sql` | Top PGA processes including background | Intermediate | YES | R12.2 |
| `13_pga_aggregate_statistics.sql` | PGA advice and workarea histogram | Advanced | YES | R12.2 |
| `14_workarea_usage.sql` | Active SQL workareas (sort/hash in PGA) | Advanced | YES | R12.2 |
## 12_Redo_Archive

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_redo_log_groups.sql` | Redo group configuration | Basic | YES | R12.2 |
| `02_redo_members.sql` | Redo member paths and status | Basic | YES | R12.2 |
| `03_current_redo_log.sql` | Which redo group is CURRENT per thread | Basic | YES | R12.2 |
| `04_redo_log_status.sql` | All group statuses including CLEARING/UNUSED | Basic | YES | R12.2 |
| `05_redo_generation_rate.sql` | Redo generation rate from V$SYSSTAT / archived logs | Advanced | YES | R12.2 |
| `06_archive_destination.sql` | Archive destinations configuration | Intermediate | YES | R12.2 |
| `07_archive_log_status.sql` | Recent archived logs and completion | Intermediate | YES | R12.2 |
| `08_archive_gap.sql` | Archive gaps (primary view of standby lag files) | Advanced | YES | R12.2 |
| `09_archive_errors.sql` | Destinations in ERROR / DEFERRED | Intermediate | YES | R12.2 |
| `10_archive_generation.sql` | Archive generation per hour (capacity) | Intermediate | YES | R12.2 |
| `11_log_switches.sql` | Log switch history from V$LOG_HISTORY | Intermediate | YES | R12.2 |
| `12_excessive_log_switches.sql` | Flag switch storms (< 2 minutes apart) | Advanced | YES | R12.2 |
| `13_redo_contention.sql` | Redo allocation / copy latch and wait events | Advanced | YES | R12.2 |
| `14_log_file_sync_analysis.sql` | Redo-folder companion to 09/17 log file sync | Advanced | YES | R12.2 |
## 13_UNDO

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_undo_tablespaces.sql` | Undo tablespaces, files, and retention guarantee | Basic | YES | R12.2 |
| `02_undo_usage.sql` | Undo extent status and file fill | Intermediate | YES | R12.2 |
| `03_active_undo.sql` | Who holds ACTIVE undo (open transactions) | Advanced | YES | R12.2 |
| `04_long_running_transactions.sql` | Transactions open longer than &minutes | Advanced | YES | R12.2 |
| `05_ora_01555_investigation.sql` | Snapshot too old evidence (V$UNDOSTAT SSOLDERRCNT) | Advanced | YES | R12.2 |
| `06_undo_retention.sql` | undo_retention vs tuned retention vs guarantee | Intermediate | YES | R12.2 |
| `07_undo_tuning.sql` | Sizing estimate from undo stats | Advanced | YES | R12.2 |
## 14_TEMP

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_temp_usage.sql` | Temporary tablespace fill level | Intermediate | YES | R12.2 |
| `02_temp_usage_by_session.sql` | TEMP by session | Intermediate | YES | R12.2 |
| `03_temp_usage_by_sql.sql` | TEMP aggregated by SQL_ID | Intermediate | YES | R12.2 |
| `04_temp_spills.sql` | Evidence of PGA workarea spills to TEMP | Advanced | YES | R12.2 |
| `05_sort_usage.sql` | Sort segment usage only | Intermediate | YES | R12.2 |
| `06_hash_usage.sql` | Hash workarea TEMP usage | Intermediate | YES | R12.2 |
## 15_RAC

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_cluster_status.sql` | cluster_database and instance membership | Basic | YES | R12.2 |
| `02_instance_status.sql` | Per-instance status, blocked, logins | Basic | YES | R12.2 |
| `03_rac_services.sql` | Services, preferred instances, and running where | Intermediate | YES | R12.2 |
| `04_instance_load.sql` | Load comparison: sessions, DB CPU, AAS-ish | Advanced | YES | R12.2 |
| `05_sessions_by_instance.sql` | User session spread | Basic | YES | R12.2 |
| `06_sql_by_instance.sql` | Same SQL_ID elapsed by instance | Advanced | YES | R12.2 |
| `07_global_cache_waits.sql` | Global cache wait summary | Advanced | YES | R12.2 |
| `08_gc_cr_requests.sql` | GC CR (consistent read) traffic | Advanced | YES | R12.2 |
| `09_gc_current_requests.sql` | GC current (DML) traffic | Advanced | YES | R12.2 |
| `10_block_transfers.sql` | Cache transfer counts between instances | Advanced | YES | R12.2 |
| `11_rac_blocking_sessions.sql` | Pointer to RAC lock script plus local check | Advanced | YES | R12.2 |
| `12_interconnect_checks.sql` | Interconnect devices and GC lost blocks | Advanced | YES | R12.2 |
| `13_service_distribution.sql` | Sessions per service per instance | Intermediate | YES | R12.2 |
| `14_node_imbalance.sql` | Combined imbalance score (sessions, DB time, GC) | Advanced | YES | R12.2 |
## 16_ASM

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_asm_diskgroups.sql` | Diskgroup inventory and state | Basic | YES | R12.2 |
| `02_diskgroup_usage.sql` | Usage with 70/85/95 bands using usable space | Intermediate | YES | R12.2 |
| `03_disk_usage.sql` | Per-disk size and used | Intermediate | YES | R12.2 |
| `04_disk_status.sql` | Disks not ONLINE / HEADER not MEMBER | Intermediate | YES | R12.2 |
| `05_failure_groups.sql` | Failure group layout | Advanced | YES | R12.2 |
| `06_asm_clients.sql` | Who is using the diskgroups | Intermediate | YES | R12.2 |
| `07_asm_rebalance.sql` | Rebalance operations in progress | Advanced | YES | R12.2 |
| `08_rebalance_power.sql` | Current power and how to change it (generated) | Advanced | YES | R12.2 |
| `09_asm_attributes.sql` | Diskgroup attributes (compatible, au_size, thin_provisioned) | Advanced | YES | R12.2 |
| `10_asm_disk_performance.sql` | Disk-level I/O stats from ASM | Advanced | YES | R12.2 |
| `11_space_forecasting.sql` | Simple days-to-full estimate from two snapshots of FREE_MB | Advanced | YES | R12.2 |
## 17_DataGuard

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_database_role.sql` | Confirm DATABASE_ROLE on this member | Basic | YES | R12.2 |
| `02_protection_mode.sql` | Maximum Performance / Availability / Protection | Intermediate | YES | R12.2 |
| `03_transport_status.sql` | Redo transport (LNS/ARCH) health | Advanced | YES | R12.2 |
| `04_apply_status.sql` | Apply / MRP running? | Advanced | YES | R12.2 |
| `05_apply_lag.sql` | Apply lag from V$DATAGUARD_STATS | Advanced | YES | R12.2 |
| `06_transport_lag.sql` | Transport lag | Advanced | YES | R12.2 |
| `07_archive_gap.sql` | Gaps on standby | Advanced | YES | R12.2 |
| `08_destination_status.sql` | All dests including local | Intermediate | YES | R12.2 |
| `09_standby_status.sql` | Standby database view (role, recover, FSFO) | Advanced | YES | R12.2 |
| `10_mrp_status.sql` | MRP0 detail | Advanced | YES | R12.2 |
| `11_rfs_status.sql` | RFS processes (standby receivers) | Advanced | YES | R12.2 |
| `12_broker_status.sql` | Data Guard broker configuration (SQL + DGMGRL hints) | Advanced | YES | R12.2 |
| `13_switchover_readiness.sql` | SWITCHOVER_STATUS and sessions | Advanced | YES | R12.2 |
| `14_failover_readiness.sql` | Failover readiness and FSFO observer notes | Advanced | YES | R12.2 |
## 18_Backup_Recovery

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_rman_configuration.sql` | RMAN persistent configuration (from the DB) | Intermediate | YES | R12.2 |
| `02_rman_backups.sql` | Recent RMAN backup jobs | Intermediate | YES | R12.2 |
| `03_backup_status.sql` | Latest backup per type | Intermediate | YES | R12.2 |
| `04_failed_backups.sql` | Failed / incomplete RMAN jobs | Intermediate | YES | R12.2 |
| `05_backup_duration.sql` | Backup runtime trend | Intermediate | YES | R12.2 |
| `06_backup_size.sql` | Backup piece sizes from V$BACKUP_PIECE | Intermediate | YES | R12.2 |
| `07_archive_backup.sql` | Archivelog backup coverage | Advanced | YES | R12.2 |
| `08_controlfile_backup.sql` | Control file autobackup and recent copies | Intermediate | YES | R12.2 |
| `09_spfile_backup.sql` | SPFILE included in autobackup | Basic | YES | R12.2 |
| `10_recovery_catalog.sql` | Is a recovery catalog in use (from the target) | Advanced | YES | R12.2 |
| `11_rman_validation.sql` | How to validate backups (commands only) | Advanced | YES | R12.2 |
| `12_database_recoverability.sql` | Recoverability to a point in time (V$RECOVER_FILE / backup redologs) | Advanced | YES | R12.2 |
| `13_restore_validation.sql` | RESTORE PREVIEW / VALIDATE workflow (manual) | Advanced | YES | R12.2 |
| `14_backup_retention.sql` | Retention policy vs FRA and obsolete backups | Advanced | YES | R12.2 |
## 19_Auditing_Security

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_audit_configuration.sql` | Unified audit vs traditional audit_trail parameter | Intermediate | YES | R12.2 |
| `02_audit_policies.sql` | All unified audit policies | Intermediate | YES | R12.2 |
| `03_enabled_policies.sql` | Which unified policies are enabled and on whom | Intermediate | YES | R12.2 |
| `04_audit_trail_location.sql` | Where audit records live and AUDSYS storage | Advanced | YES | R12.2 |
| `05_audit_records.sql` | Recent unified audit records (time-bounded) | Advanced | YES | R12.2 |
| `06_audit_growth.sql` | Audit volume per day (capacity) | Advanced | YES | R12.2 |
| `07_audit_purge.sql` | Audit trail purge — generate DBMS_AUDIT_MGMT calls only | Advanced | YES | R12.2 |
| `08_login_auditing.sql` | Successful and failed logons | Intermediate | YES | R12.2 |
| `09_privileged_user_auditing.sql` | SYS/SYSTEM/DBA activity | Advanced | YES | R12.2 |
| `10_ddl_auditing.sql` | DDL statements in the unified trail | Advanced | YES | R12.2 |
| `11_dml_auditing.sql` | DML audit records (use only if a DML policy exists) | Advanced | YES | R12.2 |
| `12_failed_login_auditing.sql` | Failed logins only (1017/28000) | Intermediate | YES | R12.2 |
| `13_data_access_auditing.sql` | SELECT audit / FGA-style access on sensitive objects | Advanced | YES | R12.2 |
## 20_Oracle_EBS

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_ebs_database_information.sql` | EBS database name, apps user, and character set context | Basic | YES | R12.2 |
| `02_ebs_application_information.sql` | Registered applications and basepath | Basic | YES | R12.2 |
| `03_ebs_release_version.sql` | EBS release, RDBMS, and product versions | Basic | YES | R12.2 |
| `04_ad_txk_versions.sql` | AD and TXK codelevels (R12.2 adop prerequisites) | Intermediate | YES | R12.2 |
| `05_applsys_information.sql` | APPLSYS schema objects and invalids | Intermediate | YES | R12.2 |
| `06_fnd_schemas.sql` | FND / Oracle user mapping (FND_ORACLE_USERID) | Intermediate | YES | R12.2 |
| `07_ebs_users.sql` | FND_USER application users (not database users) | Basic | YES | R12.2 |
| `08_responsibilities.sql` | Responsibility inventory | Basic | YES | R12.2 |
| `09_menus.sql` | Menus and menu entries for a responsibility | Intermediate | YES | R12.2 |
| `10_concurrent_programs.sql` | Concurrent program definitions | Intermediate | YES | R12.2 |
| `11_executables.sql` | Concurrent executables (spawn, PL/SQL, host, java) | Intermediate | YES | R12.2 |
| `12_request_groups.sql` | Request groups and program assignments | Intermediate | YES | R12.2 |
| `13_profiles.sql` | Profile option values at site/app/resp/user | Intermediate | YES | R12.2 |
| `14_forms.sql` | Forms and form functions | Intermediate | YES | R12.2 |
| `15_packages.sql` | APPS packages invalid or recently changed | Intermediate | YES | R12.2 |
| `16_invalid_objects.sql` | EBS-relevant invalid objects (product schemas) | Intermediate | YES | R12.2 |
| `17_ebs_database_objects.sql` | Object counts for EBS product schemas | Basic | YES | R12.2 |
| `18_ebs_schema_growth.sql` | EBS schema sizes | Intermediate | YES | R12.2 |
| `19_ebs_table_growth.sql` | Largest EBS tables | Intermediate | YES | R12.2 |
| `20_ebs_index_growth.sql` | Largest EBS indexes | Intermediate | YES | R12.2 |
## 21_EBS_Concurrent_Managers

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_concurrent_manager_status.sql` | Concurrent manager target vs actual processes and enabled flag | Intermediate | YES | R12.2 |
| `02_managers_running.sql` | Managers that currently have OS/DB processes | Intermediate | YES | R12.2 |
| `03_manager_specialization.sql` | Specialization rules (include/exclude programs) | Advanced | YES | R12.2 |
| `04_manager_processes.sql` | All concurrent process rows including inactive | Intermediate | YES | R12.2 |
| `05_target_processes.sql` | Target processes vs work shifts (capacity plan) | Intermediate | YES | R12.2 |
| `06_actual_processes.sql` | Actual vs target with alert bands | Intermediate | YES | R12.2 |
| `07_work_shifts.sql` | Work shifts assigned to managers | Intermediate | YES | R12.2 |
| `08_manager_queue.sql` | Pending requests waiting on each manager (queue depth) | Advanced | YES | R12.2 |
| `09_failed_managers.sql` | Managers that deactivated or have control codes other than Normal | Advanced | YES | R12.2 |
| `10_restart_investigation.sql` | Why managers die after start (logs, env, DB session) | Advanced | YES | R12.2 |
| `11_internal_concurrent_manager.sql` | Internal Concurrent Manager (ICM) health | Intermediate | YES | R12.2 |
| `12_standard_manager.sql` | Standard Manager depth and current requests | Intermediate | YES | R12.2 |
| `13_conflict_resolution_manager.sql` | Conflict Resolution Manager (incompatibilities / Standby) | Advanced | YES | R12.2 |
| `14_transaction_manager.sql` | Transaction managers (PO/INV/etc. AQ / TM) | Advanced | YES | R12.2 |
| `15_manager_not_processing.sql` | Why a manager is not picking up requests — checklist query | Advanced | YES | R12.2 |
## 22_EBS_Concurrent_Requests

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_running_requests.sql` | Currently running concurrent requests with elapsed time | Basic | YES | R12.2 |
| `02_pending_requests.sql` | Pending requests by status (Normal/Standby/Scheduled/Inactive) | Basic | YES | R12.2 |
| `03_completed_requests.sql` | Recently completed requests | Basic | YES | R12.2 |
| `04_failed_requests.sql` | Error / warning / terminated requests | Intermediate | YES | R12.2 |
| `05_long_running_requests.sql` | Running requests longer than 60 minutes (default) | Intermediate | YES | R12.2 |
| `06_requests_running_over_x_hours.sql` | Running requests longer than &hours (parameterized) | Intermediate | YES | R12.2 |
| `07_requests_by_program.sql` | Request history for one program name | Intermediate | YES | R12.2 |
| `08_requests_by_user.sql` | Requests submitted by one FND user | Intermediate | YES | R12.2 |
| `09_requests_by_responsibility.sql` | Requests by responsibility | Intermediate | YES | R12.2 |
| `10_requests_by_manager.sql` | Running requests grouped by controlling manager | Intermediate | YES | R12.2 |
| `11_requests_by_phase_status.sql` | Phase/status histogram (current workload picture) | Basic | YES | R12.2 |
| `12_request_history.sql` | One request_id full history row (arguments, log, parent) | Basic | YES | R12.2 |
| `13_average_runtime.sql` | Average / p95 runtime per program (last 14 days, completed normal) | Advanced | YES | R12.2 |
| `14_top_long_running_programs.sql` | Programs that consumed the most concurrent runtime last 7 days | Advanced | YES | R12.2 |
| `15_concurrent_request_sql.sql` | Map a request to SQL_ID via session / module | Advanced | YES | R12.2 |
| `16_request_wait_analysis.sql` | Wait events for running request sessions | Advanced | YES | R12.2 |
| `17_concurrent_request_performance.sql` | One program: last runs vs baseline (duration + status) | Advanced | YES | R12.2 |
## 23_EBS_Workflows

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_workflow_status.sql` | Open workflow items by item type and status | Intermediate | YES | R12.2 |
| `02_failed_workflows.sql` | Errored workflow activities (WF_ITEM_ACTIVITY_STATUSES) | Advanced | YES | R12.2 |
| `03_stuck_workflows.sql` | Open items with no recent activity (stuck) | Advanced | YES | R12.2 |
| `04_pending_activities.sql` | Activities in DEFERRED / NOTIFIED / WAITING | Advanced | YES | R12.2 |
| `05_workflow_errors.sql` | WF_ITEMS / error monitor (WF_ITEM_ACTIVITY_STATUSES error columns) | Advanced | YES | R12.2 |
| `06_workflow_background_processes.sql` | Workflow Background Process concurrent requests | Intermediate | YES | R12.2 |
| `07_workflow_agent_listeners.sql` | Workflow agent listeners / service components (R12.2 OAM) | Advanced | YES | R12.2 |
| `08_long_running_workflow_activities.sql` | Activities in ACTIVE / DEFERRED for a long time | Advanced | YES | R12.2 |
## 24_EBS_Interfaces

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_interface_tables.sql` | Catalog of common R12.2 interface tables and current row counts | Intermediate | YES | R12.2 |
| `02_failed_interface_records.sql` | Generic pattern: records with ERROR / REJECTED status across modules | Advanced | YES | R12.2 |
| `03_pending_interface_records.sql` | Unprocessed / NEW / PENDING interface rows | Advanced | YES | R12.2 |
| `04_error_records.sql` | Sample error messages (not just counts) | Advanced | YES | R12.2 |
| `05_interface_processing_time.sql` | Import program runtimes (ties interfaces to concurrent programs) | Intermediate | YES | R12.2 |
| `06_interface_program_status.sql` | Is the import scheduled and succeeding? | Intermediate | YES | R12.2 |
| `07_high_volume_interface_analysis.sql` | Which interface is largest / growing (segment size) | Advanced | YES | R12.2 |
| `08_ap_interfaces.sql` | Payables Open Interface (AP_INVOICES_INTERFACE) | Advanced | YES | R12.2 |
| `09_ar_interfaces.sql` | Autoinvoice (RA_INTERFACE_LINES_ALL) | Advanced | YES | R12.2 |
| `10_gl_interfaces.sql` | GL_INTERFACE / Journal Import | Advanced | YES | R12.2 |
| `11_po_interfaces.sql` | Purchasing document open interface | Advanced | YES | R12.2 |
| `12_inv_interfaces.sql` | Inventory transaction and item interfaces | Advanced | YES | R12.2 |
| `13_om_interfaces.sql` | Order Import (OE_HEADERS_IFACE_ALL / OE_LINES_IFACE_ALL) | Advanced | YES | R12.2 |
| `14_hr_interfaces.sql` | HR / Payroll API transactions and common staging | Advanced | YES | R12.2 |
| `15_pa_interfaces.sql` | Projects transaction import (PA_TRANSACTION_INTERFACE_ALL) | Advanced | YES | R12.2 |
## 25_EBS_Concurrent_SQL_Troubleshooting

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_find_long_running_request.sql` | Step 1 — find the long-running concurrent request | Advanced | YES | R12.2 |
| `02_find_oracle_session.sql` | Step 2 — find the Oracle session for a request | Advanced | YES | R12.2 |
| `03_find_sql_id.sql` | Step 3 — capture SQL_ID (current and previous) | Advanced | YES | R12.2 |
| `04_find_sql_text.sql` | Step 4 — SQL text | Advanced | YES | R12.2 |
| `05_find_execution_plan.sql` | Step 5 — execution plan | Advanced | YES | R12.2 |
| `06_check_wait_event.sql` | Step 6 — current and session wait events | Advanced | YES | R12.2 |
| `07_check_blocking_session.sql` | Step 7 — blocker for the request session | Advanced | YES | R12.2 |
| `08_check_cpu_consumption.sql` | Step 8 — CPU used by the session | Advanced | YES | R12.2 |
| `09_check_logical_reads.sql` | Step 9 — logical I/O (buffer gets) | Advanced | YES | R12.2 |
| `10_check_physical_reads.sql` | Step 10 — physical reads | Advanced | YES | R12.2 |
| `11_check_temp_usage.sql` | Step 11 — TEMP for the session | Advanced | YES | R12.2 |
| `12_check_pga_usage.sql` | Step 12 — PGA for the session | Advanced | YES | R12.2 |
| `13_check_io.sql` | Step 13 — I/O bytes and requests | Advanced | YES | R12.2 |
| `14_check_execution_count.sql` | Step 14 — executions of the SQL_ID | Advanced | YES | R12.2 |
| `15_check_execution_plan_changes.sql` | Step 15 — plan hashes over time (AWR) | Advanced | YES | R12.2 |
| `16_check_bind_variables.sql` | Step 16 — captured binds | Advanced | YES | R12.2 |
| `17_check_optimizer_statistics.sql` | Step 17 — stats on objects in the plan | Advanced | YES | R12.2 |
| `18_check_indexes.sql` | Step 18 — indexes on tables used by the SQL | Advanced | YES | R12.2 |
| `19_check_table_growth.sql` | Step 19 — size of tables in the plan | Advanced | YES | R12.2 |
| `20_check_concurrent_manager_impact.sql` | Step 20 — is this request blocking the managers? | Advanced | YES | R12.2 |
| `21_master_troubleshooting.sql` | Master correlation: Request → Session → SQL → Plan → Wait → Blocker → Resources → Action | Advanced | YES | R12.2 |
## 26_EBS_Performance

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_ebs_top_sql.sql` | Top SQL from sessions that look like EBS (APPS / MODULE set) | Advanced | YES | R12.2 |
| `02_ebs_top_modules.sql` | DB time by MODULE (forms and concurrent programs) | Advanced | YES | R12.2 |
| `03_ebs_top_programs.sql` | Top concurrent programs by DB-side load (running now) | Intermediate | YES | R12.2 |
| `04_sql_by_concurrent_request.sql` | SQL_ID for one request_id (performance folder shortcut) | Intermediate | YES | R12.2 |
| `05_sql_by_module.sql` | SQL cache filtered to one MODULE | Intermediate | YES | R12.2 |
| `06_sql_by_program.sql` | SQL for sessions whose MODULE matches a concurrent program name | Advanced | YES | R12.2 |
| `07_sql_by_responsibility.sql` | Active APPS sessions by action/responsibility hint | Advanced | YES | R12.2 |
| `08_ebs_database_load.sql` | EBS-oriented load snapshot (APPS sessions + time model) | Intermediate | YES | R12.2 |
| `09_ebs_active_sessions.sql` | All ACTIVE APPS sessions with request mapping when possible | Intermediate | YES | R12.2 |
| `10_ebs_wait_events.sql` | Wait events for APPS sessions only | Intermediate | YES | R12.2 |
| `11_ebs_cpu_consumption.sql` | CPU by APPS session (SESSTAT) | Advanced | YES | R12.2 |
| `12_ebs_io.sql` | Physical I/O by APPS session | Advanced | YES | R12.2 |
| `13_ebs_temp_usage.sql` | TEMP used by APPS / concurrent sessions | Intermediate | YES | R12.2 |
| `14_ebs_blocking_sessions.sql` | Blocking chains involving APPS | Intermediate | YES | R12.2 |
| `15_ebs_performance_baseline.sql` | Numbers to save each week (EBS baseline) | Intermediate | YES | R12.2 |
## 27_EBS_Users_Responsibilities

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_ebs_users.sql` | FND_USER inventory (active vs end-dated) | Basic | YES | R12.2 |
| `02_user_status.sql` | Users who cannot log in (end-dated / no logon) | Basic | YES | R12.2 |
| `03_responsibilities.sql` | All responsibilities with application and request group | Basic | YES | R12.2 |
| `04_user_responsibilities.sql` | Responsibilities assigned to one user | Intermediate | YES | R12.2 |
| `05_menus.sql` | Menu attached to a responsibility | Intermediate | YES | R12.2 |
| `06_functions.sql` | Functions a user can reach (via one responsibility menu — not exclusions) | Advanced | YES | R12.2 |
| `07_profile_options.sql` | Profile values for one user or site | Intermediate | YES | R12.2 |
| `08_inactive_users.sql` | Active FND users with no last_logon in 180 days | Intermediate | YES | R12.2 |
| `09_end_dated_users.sql` | Recently end-dated users (leaver check) | Basic | YES | R12.2 |
| `10_responsibility_assignments.sql` | Who has a given responsibility (SoD helper) | Intermediate | YES | R12.2 |
## 28_EBS_Objects

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_fnd_objects.sql` | FND / APPLSYS object counts and invalids | Basic | YES | R12.2 |
| `02_custom_objects.sql` | Custom XX schema objects | Intermediate | YES | R12.2 |
| `03_invalid_ebs_objects.sql` | Invalids in APPS, APPLSYS, and product schemas | Intermediate | YES | R12.2 |
| `04_custom_schema_objects.sql` | All non-Oracle-maintained schemas that are not product schemas | Advanced | YES | R12.2 |
| `05_ebs_packages.sql` | Invalid or recently changed APPS packages | Intermediate | YES | R12.2 |
| `06_ebs_triggers.sql` | Triggers on EBS product tables (custom risk) | Advanced | YES | R12.2 |
| `07_xx_custom_objects.sql` | Objects whose names start with XX in APPS/custom schemas | Intermediate | YES | R12.2 |
## 29_EBS_Health_Check

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_ebs_health_check.sql` | EBS + database health check with OK / WARNING / CRITICAL | Advanced | YES | R12.2 |
## 30_Advanced_Troubleshooting

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_database_suddenly_slow.sql` | Database suddenly slow | Advanced | YES | N/A |
| `02_cpu_suddenly_high.sql` | CPU suddenly high | Advanced | YES | N/A |
| `03_io_suddenly_high.sql` | I/O suddenly high | Advanced | YES | N/A |
| `04_sessions_suddenly_increase.sql` | Sessions suddenly increase | Advanced | YES | N/A |
| `05_database_connection_issues.sql` | Database connection issues | Advanced | YES | N/A |
| `06_ora_00060_deadlock.sql` | ORA-00060 deadlock | Advanced | YES | N/A |
| `07_ora_01555_snapshot_too_old.sql` | ORA-01555 snapshot too old | Advanced | YES | N/A |
| `08_ora_04031_shared_pool.sql` | ORA-04031 shared pool | Advanced | YES | N/A |
| `09_ora_04030_pga_memory.sql` | ORA-04030 PGA / process memory | Advanced | YES | N/A |
| `10_ora_01652_temp.sql` | ORA-01652 unable to extend TEMP | Advanced | YES | N/A |
| `11_ora_01653_unable_to_extend.sql` | ORA-01653/01654 unable to extend table/index | Advanced | YES | N/A |
| `12_ora_30036_undo_space.sql` | ORA-30036 unable to extend undo | Advanced | YES | N/A |
| `13_ora_01536_quota_exceeded.sql` | ORA-01536 quota exceeded | Advanced | YES | N/A |
| `14_ora_00054_resource_busy.sql` | ORA-00054 resource busy (DDL / lock) | Advanced | YES | N/A |
| `15_ora_01000_open_cursors.sql` | ORA-01000 maximum open cursors | Advanced | YES | N/A |
| `16_ora_07445.sql` | ORA-07445 exception (process crash) | Advanced | YES | N/A |
| `17_ora_00600.sql` | ORA-00600 internal error | Advanced | YES | N/A |
| `18_blocking_chains.sql` | Blocking chains (advanced playbook) | Advanced | YES | N/A |
| `19_library_cache_contention.sql` | Library cache / cursor pin contention | Advanced | YES | N/A |
| `20_high_parse_rate.sql` | High parse rate | Advanced | YES | N/A |
| `21_high_db_cpu.sql` | High DB CPU playbook | Advanced | YES | N/A |
| `22_high_db_time.sql` | High DB time playbook | Advanced | YES | R12.2 |
| `23_connection_saturation.sql` | Connection / process saturation | Advanced | YES | N/A |
## 31_Quick_Reference

| Script | Purpose | Difficulty | Production | EBS |
|---|---|---|---|---|
| `01_DBA_Quick_Reference.sql` | Daily production DBA quick reference (pack-free) | Intermediate | YES | N/A |
| `02_EBS_DBA_Quick_Reference.sql` | Daily EBS DBA quick reference | Intermediate | YES | R12.2 |
| `03_Performance_Troubleshooting_Quick_Reference.sql` | Performance incident first five minutes | Advanced | YES | R12.2 |
| `04_Production_Incident_Quick_Reference.sql` | Production incident command board (what to collect, what not to do) | Advanced | YES | N/A |

