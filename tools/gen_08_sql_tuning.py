#!/usr/bin/env python3
from _writer import Query, Script, write_many

PACK = "LICENSING: Real-Time SQL Monitor (V$SQL_MONITOR) requires Tuning Pack when used via OEM/DBMS_SQLTUNE historically; V$SQL_MONITOR access is Tuning Pack. DBMS_SQLTUNE / SQL Tuning Advisor is Tuning Pack. DBA_HIST_* and ASH are Diagnostics Pack. EXPLAIN PLAN and DBMS_XPLAN.DISPLAY_CURSOR (V$SQL_PLAN) are not pack-licensed."


def scripts():
    return [
        Script(
            folder="08_SQL_Tuning",
            file_name="01_sql_monitor.sql",
            category="08_SQL_Tuning",
            purpose="Real-Time SQL Monitor status for long-running statements",
            difficulty="Advanced",
            production_use="YES",
            extra_header=PACK,
            description="""V$SQL_MONITOR shows statements that ran long enough to be
monitored (typically >5 seconds or parallel). Best live view of
elapsed, CPU, I/O, and degree of parallelism for one execution.""",
            queries=[
                Query(
                    title="Recent monitored executions",
                    what="Reads GV$SQL_MONITOR for the last day of captured executions.",
                    columns="SQL_ID, STATUS, ELAPSED_S, CPU_S, PX_SERVERS, SID.",
                    interpret="STATUS EXECUTING is live. DONE (ERROR) failed. Compare ELAPSED to QUEUING.",
                    problem="A statement EXECUTING for hours with BUFFER_GETS climbing and little I/O — CPU/spin or a bad join.",
                    action="Note SQL_ID and KEY, then DISPLAY_CURSOR / report_sql_monitor. Tuning Pack.",
                    caution="Tuning Pack. Query is relatively cheap with a time filter.",
                    privileges="SELECT on GV_$SQL_MONITOR",
                    notes="Requires Tuning Pack.",
                    sql="""SELECT
       inst_id,
       sid,
       session_serial#,
       sql_id,
       sql_exec_id,
       sql_exec_start,
       status,
       username,
       module,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       ROUND(cpu_time/1e6,1) AS cpu_s,
       buffer_gets,
       disk_reads,
       px_servers_allocated
FROM   gv$sql_monitor
WHERE  sql_exec_start > SYSDATE - 1
ORDER BY elapsed_time DESC
FETCH FIRST 40 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="02_execution_plan.sql",
            category="08_SQL_Tuning",
            purpose="Display the actual cursor plan for a SQL_ID (DBMS_XPLAN)",
            difficulty="Intermediate",
            production_use="YES",
            extra_header="DISPLAY_CURSOR uses V$SQL_PLAN — no Diagnostics Pack required.",
            description="""Gets the plan of a cursor still in cache. Use ALLSTATS LAST if
the statement was executed with GATHER_PLAN_STATISTICS or
statistics_level=ALL (do not set ALL on production globally).""",
            queries=[
                Query(
                    title="DBMS_XPLAN.DISPLAY_CURSOR",
                    what="Calls DBMS_XPLAN for &sql_id and optional child.",
                    columns="PLAN_TABLE_OUTPUT.",
                    interpret="Look at cardinality estimates vs actuals (if ALLSTATS). Nested loops on large row sources, wrong join order, implicit conversions.",
                    problem="Estimated rows 1, actual millions.",
                    action="Fix stats, predicates, or add a baseline. Do not set optimizer_index_cost_adj as a first fix.",
                    caution="Safe. statistics_level=ALL is NOT recommended instance-wide.",
                    privileges="SELECT on V_$SQL_PLAN, V_$SQL. Execute DBMS_XPLAN.",
                    sql="""DEFINE sql_id = 0w6u2qj2zn5hs
DEFINE child  = 0

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', &child, 'TYPICAL +PEEKED_BINDS +OUTLINE'));

-- If you enabled rowsource stats for a single session test (not production-wide):
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', &child, 'ALLSTATS LAST +PEEKED_BINDS'));""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="03_sql_plan_history.sql",
            category="08_SQL_Tuning",
            purpose="Historical plans from AWR (DISPLAY_AWR)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack required for DBA_HIST_SQL_PLAN / DISPLAY_AWR.",
            description="""Shows plans that are no longer in cache. Different from
07_Performance_Tuning/13 which is metrics-over-time; this prints the plan text.""",
            queries=[
                Query(
                    title="AWR plans for a SQL_ID",
                    what="Lists plan hashes then DISPLAY_AWR.",
                    columns="PLAN_HASH_VALUE, TIMESTAMP, PLAN_TABLE_OUTPUT.",
                    interpret="Compare two plan hashes from before/after the incident.",
                    problem="The current plan is the expensive one and the old hash is known-good.",
                    action="Load a SQL plan baseline from the good AWR plan (Tuning Pack / SPM).",
                    caution="Pack licensed.",
                    privileges="SELECT on DBA_HIST_SQL_PLAN. EXECUTE DBMS_XPLAN.",
                    notes="Requires Diagnostics Pack.",
                    sql="""DEFINE sql_id = 0w6u2qj2zn5hs

SELECT DISTINCT plan_hash_value, timestamp
FROM   dba_hist_sql_plan
WHERE  sql_id = '&sql_id'
ORDER BY timestamp DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_AWR('&sql_id'));""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="04_sql_tuning_advisor.sql",
            category="08_SQL_Tuning",
            purpose="How to invoke SQL Tuning Advisor (commands generated, not auto-run)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Tuning Pack required. Do not run advisor on production peak without a window — it executes test queries.",
            description="""SQL Tuning Advisor can recommend indexes, profiles, and stats.
It is a change-control activity. This file only shows the API.""",
            queries=[
                Query(
                    title="Advisor API (commented — do not auto-execute)",
                    what="Prints DBMS_SQLTUNE usage as comments.",
                    columns="N/A",
                    interpret="A profile is a safer first accept than a new index.",
                    problem="Advisor hung because the SQL is extremely expensive — use time limits.",
                    action="Create a tuning task in a window. Review before ACCEPT_SQL_PROFILE.",
                    caution="WARNING: Advisor executes SQL. Tuning Pack. Not auto-run.",
                    privileges="ADVISOR privilege. Tuning Pack.",
                    notes="Requires Tuning Pack.",
                    sql="""PROMPT SQL Tuning Advisor requires Tuning Pack and ADVISOR privilege.
PROMPT Example (run manually in a change window):

/*
DECLARE
  l_task VARCHAR2(64);
BEGIN
  l_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(
              sql_id   => '0w6u2qj2zn5hs',
              scope    => 'COMPREHENSIVE',
              time_limit => 300,
              task_name  => 'TUNED_0w6u2qj2zn5hs');
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK(task_name => 'TUNED_0w6u2qj2zn5hs');
END;
/

SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('TUNED_0w6u2qj2zn5hs') FROM dual;

-- WARNING: ACCEPT_SQL_PROFILE changes optimizer behavior.
-- EXEC DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name => 'TUNED_0w6u2qj2zn5hs', name => 'PROF_0w6u2qj2zn5hs');
*/

SELECT task_name, status, execution_start
FROM   dba_advisor_tasks
WHERE  advisor_name = 'SQL Tuning Advisor'
ORDER BY execution_start DESC NULLS LAST
FETCH FIRST 20 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="05_sql_profiles.sql",
            category="08_SQL_Tuning",
            purpose="List existing SQL profiles",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Creating SQL profiles is Tuning Pack. Listing DBA_SQL_PROFILES is a dictionary query.",
            description="""Shows profiles already in the database so you do not create
duplicates and so you can see what was accepted after an incident.""",
            queries=[
                Query(
                    title="SQL profiles",
                    what="Reads DBA_SQL_PROFILES.",
                    columns="NAME, STATUS, SQL_TEXT, CREATED.",
                    interpret="ENABLED profiles influence matching statements. CATEGORY DEFAULT applies to all sessions unless altered.",
                    problem="A leftover profile from a test forcing a bad plan.",
                    action="DISABLE is a change. Generated only.",
                    caution="WARNING: ALTER/DROP SQL PROFILE generated only.",
                    privileges="SELECT on DBA_SQL_PROFILES",
                    sql="""SELECT
       name,
       category,
       status,
       created,
       last_modified,
       SUBSTR(sql_text,1,200) AS sql_text
FROM   dba_sql_profiles
ORDER BY created DESC;

-- WARNING: Review carefully.
-- SELECT 'EXEC DBMS_SQLTUNE.ALTER_SQL_PROFILE('''||name||''',''STATUS'',''DISABLED'');' FROM dba_sql_profiles WHERE status = 'ENABLED';""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="06_sql_baselines.sql",
            category="08_SQL_Tuning",
            purpose="List SQL plan baselines (SPM)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="SQL Plan Management is Enterprise Edition. Evolving/loading from AWR often used with Diagnostics Pack data.",
            description="""Baselines pin accepted plans. Preferred over profiles for
repeatable plan control in 19c.""",
            queries=[
                Query(
                    title="SQL plan baselines",
                    what="Reads DBA_SQL_PLAN_BASELINES.",
                    columns="SQL_HANDLE, PLAN_NAME, ENABLED, ACCEPTED, REPRODUCED.",
                    interpret="ENABLED+ACCEPTED is in force. REPRODUCED NO means the plan could not be reproduced (hint/object change).",
                    problem="A baseline not reproduced — optimizer ignores it and may pick a new expensive plan.",
                    action="Investigate object/stats changes. Do not drop baselines during an incident.",
                    caution="Safe to list. DROP/DISABLE generated only.",
                    privileges="SELECT on DBA_SQL_PLAN_BASELINES",
                    sql="""SELECT
       sql_handle,
       plan_name,
       enabled,
       accepted,
       fixed,
       reproduced,
       created,
       last_executed,
       SUBSTR(sql_text,1,160) AS sql_text
FROM   dba_sql_plan_baselines
ORDER BY created DESC;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="07_sql_patches.sql",
            category="08_SQL_Tuning",
            purpose="List SQL patches (hint-based)",
            difficulty="Advanced",
            production_use="YES",
            description="""SQL patches (DBMS_SQLDIAG_INTERNAL / DBMS_SQLPATCH in 19c
DBMS_SQLDIAG.CREATE_SQL_PATCH) attach hints without changing text.
Used as a tactical fix.""",
            queries=[
                Query(
                    title="SQL patches",
                    what="Reads DBA_SQL_PATCHES.",
                    columns="NAME, STATUS, SQL_TEXT.",
                    interpret="ENABLED patches apply hints. They are easy to forget after the root cause is fixed.",
                    problem="Conflicting patch + profile + baseline on the same SQL_ID.",
                    action="Keep one control mechanism. Disable extras with approval.",
                    caution="Safe to list.",
                    privileges="SELECT on DBA_SQL_PATCHES",
                    sql="""SELECT name, category, status, force_matching, created, SUBSTR(sql_text,1,200) sql_text
FROM   dba_sql_patches
ORDER BY created DESC;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="08_bind_peeking.sql",
            category="08_SQL_Tuning",
            purpose="Bind peek / adaptive cursor sharing status for a SQL_ID",
            difficulty="Advanced",
            production_use="YES",
            description="""Shows IS_BIND_SENSITIVE / IS_BIND_AWARE on V$SQL and peeked
binds. This is why the same SQL_ID is fast in one concurrent request
and slow in another.""",
            queries=[
                Query(
                    title="Bind-aware cursors",
                    what="Reads V$SQL bind flags and V$SQL_CS_HISTOGRAM if present.",
                    columns="CHILD_NUMBER, IS_BIND_SENSITIVE, IS_BIND_AWARE, PLAN_HASH.",
                    interpret="SENSITIVE but not AWARE means ACS has not kicked in yet. Multiple children with different plans is ACS working.",
                    problem="One peeked bind produced a nested-loop plan that is reused for a high-cardinality bind.",
                    action="See 07/16 binds. Consider ACS or a baseline per class of binds.",
                    caution="Safe.",
                    privileges="SELECT on V_$SQL",
                    sql="""DEFINE sql_id = 0w6u2qj2zn5hs

SELECT
       inst_id,
       child_number,
       plan_hash_value,
       is_bind_sensitive,
       is_bind_aware,
       is_shareable,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s
FROM   gv$sql
WHERE  sql_id = '&sql_id'
ORDER BY inst_id, child_number;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="09_adaptive_plans.sql",
            category="08_SQL_Tuning",
            purpose="Identify adaptive plans in cache",
            difficulty="Advanced",
            production_use="YES",
            description="""19c adaptive plans can switch join methods at runtime.
DISPLAY_CURSOR with ADAPTIVE shows the resolved plan.""",
            queries=[
                Query(
                    title="Adaptive notes in plans",
                    what="Searches V$SQL_PLAN for adaptive operations / notes.",
                    columns="SQL_ID, OPERATION, OPTIONS.",
                    interpret="HYBRID HASH / adaptive statistics notes indicate adaptive behavior.",
                    problem="A plan that flips during a long EBS job, changing runtime mid-flight.",
                    action="For a single critical SQL, consider OPT_PARAM('_optimizer_adaptive_plans','false') via a patch/baseline — Support/change only.",
                    caution="Safe to query. Do not disable adaptive features instance-wide mid-incident.",
                    privileges="SELECT on V_$SQL_PLAN, V_$SQL",
                    sql="""SELECT DISTINCT
       p.sql_id,
       p.plan_hash_value,
       p.operation,
       p.options
FROM   v$sql_plan p
WHERE  p.options LIKE '%ADAPTIVE%'
OR     p.operation LIKE '%ADAPTIVE%'
FETCH FIRST 40 ROWS ONLY;

PROMPT For a specific SQL:
PROMPT SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id',0,'ADAPTIVE'));""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="10_cardinality_feedback.sql",
            category="08_SQL_Tuning",
            purpose="Statistics / cardinality feedback usage on cursors",
            difficulty="Advanced",
            production_use="YES",
            description="""IS_REOPTIMIZABLE and USE_FEEDBACK_STATS (names vary) show
whether Oracle reparsed after seeing actual cardinalities.""",
            queries=[
                Query(
                    title="Reoptimization flags",
                    what="Reads GV$SQL columns related to reoptimization.",
                    columns="SQL_ID, IS_REOPTIMIZABLE, EXECUTIONS.",
                    interpret="Many reoptimizable cursors mean the first execution used a guess.",
                    problem="First execution of a concurrent program is 10x slower than the second.",
                    action="Improve stats/dynamic sampling for that SQL rather than running it twice.",
                    caution="Safe. Column names are valid on 19c V$SQL (IS_REOPTIMIZABLE).",
                    privileges="SELECT on GV_$SQL",
                    notes="Oracle 19c.",
                    sql="""SELECT
       sql_id,
       child_number,
       is_reoptimizable,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s,
       SUBSTR(sql_text,1,140) AS sql_text
FROM   gv$sql
WHERE  is_reoptimizable = 'Y'
ORDER BY elapsed_time DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="11_awr_report_generation.sql",
            category="08_SQL_Tuning",
            purpose="Generate AWR report (instance or global) — instructions and snapshot IDs",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: AWR report requires Diagnostics Pack. Generating a report is relatively heavy — do not loop it.",
            description="""Lists snapshot IDs so you can run awrrpt.sql / awrgrpt.sql
manually. This file does not spool a full HTML report automatically.""",
            queries=[
                Query(
                    title="Available snapshots and how to run awrrpt",
                    what="Reads DBA_HIST_SNAPSHOT.",
                    columns="SNAP_ID, BEGIN_INTERVAL_TIME, INSTANCE_NUMBER.",
                    interpret="Pick begin/end snaps that bracket the incident, not the entire weekend.",
                    problem="No snapshots (AWR disabled or SYSAUX issue).",
                    action="If licensed, check STATISTICS_LEVEL and snapshot interval (12). Do not enable AWR if unlicensed.",
                    caution="Diagnostics Pack. awrrpt I/O on SYSAUX.",
                    privileges="SELECT on DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT instance_number, snap_id,
       TO_CHAR(begin_interval_time,'DD-MON-RR HH24:MI') begin_time,
       TO_CHAR(end_interval_time,'DD-MON-RR HH24:MI') end_time,
       snap_level,
       error_count
FROM   dba_hist_snapshot
WHERE  begin_interval_time > SYSDATE - 3
ORDER BY snap_id, instance_number;

PROMPT Run from SQL*Plus as a privileged user:
PROMPT   @$ORACLE_HOME/rdbms/admin/awrrpt.sql
PROMPT RAC global report:
PROMPT   @$ORACLE_HOME/rdbms/admin/awrgrpt.sql
PROMPT SQL-specific:
PROMPT   @$ORACLE_HOME/rdbms/admin/awrsqrpt.sql""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="12_awr_snapshots.sql",
            category="08_SQL_Tuning",
            purpose="AWR snapshot inventory and errors",
            difficulty="Intermediate",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack.",
            description="""Verifies snapshots are being taken. Missing snaps during an
outage window means you lost historical evidence.""",
            queries=[
                Query(
                    title="Snapshot coverage",
                    what="Lists recent snapshots and flush errors.",
                    columns="SNAP_ID, BEGIN_TIME, ERROR_COUNT, FLUSH_ELAPSED.",
                    interpret="ERROR_COUNT > 0 or large gaps = SYSAUX pressure or AWR hang.",
                    problem="Gap during the incident.",
                    action="Check SYSAUX space and MMON. Do not create a snapshot storm (manual create every minute).",
                    caution="Pack licensed. CREATE SNAPSHOT is a write — not executed.",
                    privileges="SELECT on DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       instance_number,
       snap_id,
       begin_interval_time,
       end_interval_time,
       flush_elapsed,
       error_count
FROM   dba_hist_snapshot
WHERE  begin_interval_time > SYSDATE - 2
ORDER BY snap_id DESC, instance_number;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="13_snapshot_interval.sql",
            category="08_SQL_Tuning",
            purpose="AWR retention and interval (DBMS_WORKLOAD_REPOSITORY)",
            difficulty="Intermediate",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack. Changing interval/retention is a change.",
            description="""Default 60 minutes / 8 days is often too coarse/short for EBS
month-end forensics. This only displays current settings.""",
            queries=[
                Query(
                    title="AWR interval and retention",
                    what="Reads DBA_HIST_WR_CONTROL.",
                    columns="SNAP_INTERVAL, RETENTION, TOPNSQL.",
                    interpret="SNAP_INTERVAL +000 01:00:00 is hourly. RETENTION +008 is 8 days.",
                    problem="Interval 60 min hiding a 10-minute spike. Retention 8 days and the complaint is 3 weeks old.",
                    action="MODIFY_SNAPSHOT_SETTINGS in a change window if licensed. More frequent snaps increase SYSAUX growth.",
                    caution="Safe to query. MODIFY not executed.",
                    privileges="SELECT on DBA_HIST_WR_CONTROL",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       dbid,
       snap_interval,
       retention,
       topnsql
FROM   dba_hist_wr_control;

PROMPT To change (manual, licensed, change window):
PROMPT   EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(interval => 30, retention => 31*24*60);""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="14_top_sql_from_awr.sql",
            category="08_SQL_Tuning",
            purpose="Top SQL from AWR by elapsed time for a time window",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack. This is the incident-window ranking — prefer this over V$SQL after the fact.",
            description="""Difference vs 07_Performance_Tuning/01: V$SQL is cache-since-load;
this is bounded by snapshot times and is what you use after a spike.""",
            queries=[
                Query(
                    title="Top AWR SQL by elapsed_delta",
                    what="Sums DBA_HIST_SQLSTAT.elapsed_time_delta between two times.",
                    columns="SQL_ID, ELA_S, EXECS, GETS.",
                    interpret="Rank by ela_s for DB time. Also scan CPU and iowait columns.",
                    problem="A new SQL_ID at the top vs last week's same-hour report.",
                    action="Take SQL_ID to plan history and EBS module mapping.",
                    caution="Pack licensed. Keep the window tight (hours, not months).",
                    privileges="SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT, DBA_HIST_SQLTEXT",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       st.sql_id,
       MIN(SUBSTR(t.sql_text,1,160)) AS sql_text,
       SUM(st.executions_delta) AS execs,
       ROUND(SUM(st.elapsed_time_delta)/1e6,1) AS ela_s,
       ROUND(SUM(st.cpu_time_delta)/1e6,1) AS cpu_s,
       SUM(st.buffer_gets_delta) AS gets,
       SUM(st.disk_reads_delta) AS reads,
       SUM(st.iowait_delta)/1e6 AS iowait_s
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
LEFT JOIN dba_hist_sqltext t
       ON t.sql_id = st.sql_id AND t.dbid = st.dbid
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
ORDER BY ela_s DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="15_awr_top_sql_cpu.sql",
            category="08_SQL_Tuning",
            purpose="Top AWR SQL by CPU for a time window",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack. Use when host CPU is the ticket, not elapsed.",
            description="""Same windowing as 14 but ordered by cpu_time_delta.""",
            queries=[
                Query(
                    title="Top AWR SQL by CPU",
                    what="Sums CPU delta from DBA_HIST_SQLSTAT.",
                    columns="SQL_ID, CPU_S, ELA_S.",
                    interpret="CPU_S ≈ ELA_S → CPU bound. ELA >> CPU → wait bound (wrong script).",
                    problem="CPU_S concentrated in one SQL_ID during the CPU spike.",
                    action="Plan/cardinality work. Check PL/SQL functions in SELECT lists.",
                    caution="Pack licensed.",
                    privileges="SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       st.sql_id,
       SUM(st.executions_delta) AS execs,
       ROUND(SUM(st.cpu_time_delta)/1e6,1) AS cpu_s,
       ROUND(SUM(st.elapsed_time_delta)/1e6,1) AS ela_s,
       SUM(st.buffer_gets_delta) AS gets
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
ORDER BY cpu_s DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="16_awr_top_sql_elapsed.sql",
            category="08_SQL_Tuning",
            purpose="Alias-style elapsed ranking with per-exec (AWR)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack. Difference vs 14: includes ela/exec so long-runners with few execs are visible.",
            description="""14 ranks total DB time. This also shows per-exec so a 1-exec
4-hour job is not hidden below a chatty SQL.""",
            queries=[
                Query(
                    title="AWR elapsed with per-exec",
                    what="Same source as 14 with ela/exec computed.",
                    columns="SQL_ID, ELA_S, ELA_PER_EXEC_S.",
                    interpret="Use total ela_s for instance impact; ela_per_exec for user pain.",
                    problem="Low execs, huge ela_per_exec — concurrent program.",
                    action="Folder 25 EBS SQL troubleshooting.",
                    caution="Pack licensed.",
                    privileges="SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       st.sql_id,
       SUM(st.executions_delta) AS execs,
       ROUND(SUM(st.elapsed_time_delta)/1e6,1) AS ela_s,
       ROUND(SUM(st.elapsed_time_delta)/NULLIF(SUM(st.executions_delta),0)/1e6,3) AS ela_per_exec_s
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
HAVING SUM(st.executions_delta) > 0
ORDER BY ela_per_exec_s DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="17_awr_top_sql_io.sql",
            category="08_SQL_Tuning",
            purpose="Top AWR SQL by I/O wait and disk reads",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack. Use when storage latency or throughput is the ticket.",
            description="""Orders by iowait_delta and disk_reads_delta.""",
            queries=[
                Query(
                    title="AWR I/O heavy SQL",
                    what="Sums iowait and disk_reads from DBA_HIST_SQLSTAT.",
                    columns="SQL_ID, IOWAIT_S, READS.",
                    interpret="High reads with low iowait = fast storage or cached. High iowait with modest reads = latency.",
                    problem="One SQL saturating the I/O subsystem.",
                    action="09 I/O waits + plan FTS/index range.",
                    caution="Pack licensed.",
                    privileges="SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       st.sql_id,
       SUM(st.executions_delta) AS execs,
       ROUND(SUM(st.iowait_delta)/1e6,1) AS iowait_s,
       SUM(st.disk_reads_delta) AS reads,
       SUM(st.physical_read_bytes_delta)/1024/1024 AS read_mb
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  sn.begin_interval_time >= SYSDATE - 1
GROUP BY st.sql_id
ORDER BY iowait_s DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="18_awr_top_wait_events.sql",
            category="08_SQL_Tuning",
            purpose="Top wait events from AWR for a window",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack.",
            description="""DBA_HIST_SYSTEM_EVENT deltas. Idle events excluded.""",
            queries=[
                Query(
                    title="AWR wait event deltas",
                    what="Computes time_waited_micro_delta from consecutive snaps via the hist view's total (uses DBA_HIST_SYSTEM_EVENT with snapshot join — time_waited is cumulative; use *_FG or compute from adjacent snaps). Uses TIME_WAITED_MICRO from hist which is cumulative; we subtract via analytic.",
                    columns="EVENT_NAME, WAIT_S, WAITS.",
                    interpret="Compare to the same hour last week. New #1 event is the clue.",
                    problem="log file sync or gc buffer busy becoming #1.",
                    action="Open the matching 09_Wait_Events script.",
                    caution="Pack licensed.",
                    privileges="SELECT on DBA_HIST_SYSTEM_EVENT, DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""WITH ev AS (
       SELECT
              sn.begin_interval_time,
              e.instance_number,
              e.event_name,
              e.wait_class,
              e.time_waited_micro
              - LAG(e.time_waited_micro) OVER (PARTITION BY e.instance_number, e.event_name ORDER BY e.snap_id) AS wait_us,
              e.total_waits
              - LAG(e.total_waits) OVER (PARTITION BY e.instance_number, e.event_name ORDER BY e.snap_id) AS waits
       FROM   dba_hist_system_event e
       JOIN   dba_hist_snapshot sn
              ON sn.snap_id = e.snap_id AND sn.dbid = e.dbid AND sn.instance_number = e.instance_number
       WHERE  sn.begin_interval_time > SYSDATE - 1
       AND    e.wait_class <> 'Idle'
)
SELECT event_name, wait_class,
       ROUND(SUM(wait_us)/1e6,1) AS wait_s,
       SUM(waits) AS waits
FROM   ev
WHERE  wait_us > 0
GROUP BY event_name, wait_class
ORDER BY wait_s DESC
FETCH FIRST 25 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="19_db_time.sql",
            category="08_SQL_Tuning",
            purpose="DB time, DB CPU, and background time from AWR / V$SYS_TIME_MODEL",
            difficulty="Advanced",
            production_use="YES",
            extra_header="V$SYS_TIME_MODEL is pack-free. DBA_HIST_SYS_TIME_MODEL is Diagnostics Pack.",
            description="""DB time is the core load metric (not host CPU). AAS ≈ DB time
in seconds / elapsed wall seconds.""",
            queries=[
                Query(
                    title="Time model now and optional AWR",
                    what="Reads GV$SYS_TIME_MODEL.",
                    columns="STAT_NAME, SECONDS.",
                    interpret="DB CPU / DB time < 0.5 means wait-dominated. Near 1.0 means CPU-dominated.",
                    problem="DB time much higher than usual for this hour.",
                    action="AAS script 20 + top SQL.",
                    caution="Safe. Hist query requires pack — included separately.",
                    privileges="SELECT on GV_$SYS_TIME_MODEL",
                    sql="""SELECT
       inst_id,
       stat_name,
       ROUND(value/1e6,1) AS seconds
FROM   gv$sys_time_model
WHERE  stat_name IN ('DB time','DB CPU','background elapsed time','background cpu time','sql execute elapsed time','parse time elapsed','hard parse elapsed time')
ORDER BY inst_id, seconds DESC;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="20_average_active_sessions.sql",
            category="08_SQL_Tuning",
            purpose="Average Active Sessions from ASH or estimated from DB time",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: GV$ACTIVE_SESSION_HISTORY is Diagnostics Pack. The V$SYS_TIME_MODEL estimate is pack-free but only a since-startup average.",
            description="""AAS is the best single load number. Compare to CPU_COUNT:
AAS on CPU > CPU_COUNT means CPU queued.""",
            queries=[
                Query(
                    title="AAS from ASH last hour (licensed) and CPU_COUNT",
                    what="Counts ASH samples / samples-per-second.",
                    columns="AAS, ON_CPU, WAITING, CPU_COUNT.",
                    interpret="AAS 40 on a 16 CPU host is overloaded. Split by wait_class.",
                    problem="AAS spike matching the user complaint.",
                    action="ASH by SQL / event (21-26).",
                    caution="ASH requires Diagnostics Pack.",
                    privileges="SELECT on GV_$ACTIVE_SESSION_HISTORY, V_$PARAMETER",
                    notes="Requires Diagnostics Pack for ASH.",
                    sql="""SELECT value AS cpu_count FROM v$parameter WHERE name = 'cpu_count';

-- Diagnostics Pack
SELECT
       ROUND(COUNT(*) / 3600, 2) AS aas_last_hour,
       ROUND(SUM(DECODE(session_state,'ON CPU',1,0))/3600,2) AS aas_on_cpu,
       ROUND(SUM(DECODE(session_state,'WAITING',1,0))/3600,2) AS aas_waiting
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - 1/24;

SELECT wait_class, ROUND(COUNT(*)/3600,2) AS aas
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - 1/24
AND    session_state = 'WAITING'
GROUP BY wait_class
ORDER BY aas DESC;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="21_ash_analysis.sql",
            category="08_SQL_Tuning",
            purpose="General ASH breakdown for the last N minutes",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack. ASH is sampled (1s in memory). Good for 'what is happening now'.",
            description="""Top-level ASH cube: SQL_ID, event, module. Start here, then
use the specific ASH scripts.""",
            queries=[
                Query(
                    title="ASH last 15 minutes",
                    what="Aggregates GV$ACTIVE_SESSION_HISTORY.",
                    columns="SQL_ID, EVENT, MODULE, SAMPLES, PCT.",
                    interpret="Samples ≈ seconds of DB time for that key (approx).",
                    problem="One SQL_ID or event owns most samples.",
                    action="Drill with 22-26.",
                    caution="Pack licensed. 15 minute window keeps it cheap.",
                    privileges="SELECT on GV_$ACTIVE_SESSION_HISTORY",
                    notes="Requires Diagnostics Pack.",
                    sql="""DEFINE minutes = 15

SELECT sql_id, NVL(event,'ON CPU') AS event, NVL(module,'-') module,
       COUNT(*) samples,
       ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),1) AS pct
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - &minutes/1440
GROUP BY sql_id, event, module
ORDER BY samples DESC
FETCH FIRST 40 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="22_ash_by_sql_id.sql",
            category="08_SQL_Tuning",
            purpose="ASH filtered to one SQL_ID",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack.",
            description="""Session-level timeline for a known SQL_ID (from a concurrent
request or V$SQL).""",
            queries=[
                Query(
                    title="ASH rows for &sql_id",
                    what="Filters ASH by SQL_ID.",
                    columns="SAMPLE_TIME, SESSION_ID, EVENT, WAIT_CLASS, BLOCKING_SESSION.",
                    interpret="See if the SQL is on CPU, I/O, or blocked over time.",
                    problem="Most samples on a lock event.",
                    action="10_Locks_Blocking.",
                    caution="Pack licensed.",
                    privileges="SELECT on GV_$ACTIVE_SESSION_HISTORY",
                    notes="Requires Diagnostics Pack.",
                    sql="""DEFINE sql_id = 0w6u2qj2zn5hs
DEFINE minutes = 60

SELECT
       inst_id,
       session_id,
       session_serial#,
       sql_id,
       sql_plan_hash_value,
       session_state,
       NVL(event,'ON CPU') event,
       wait_class,
       blocking_session,
       module,
       machine,
       sample_time
FROM   gv$active_session_history
WHERE  sql_id = '&sql_id'
AND    sample_time > SYSDATE - &minutes/1440
ORDER BY sample_time;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="23_ash_by_session.sql",
            category="08_SQL_Tuning",
            purpose="ASH for one SID/SERIAL",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack.",
            description="""Used when you already have the Oracle session for a concurrent
request or Forms user.""",
            queries=[
                Query(
                    title="ASH for one session",
                    what="Filters ASH by session_id and inst_id.",
                    columns="SAMPLE_TIME, SQL_ID, EVENT.",
                    interpret="SQL_ID changing over time is a Forms session doing many statements. One SQL_ID stuck is a long call.",
                    problem="Same SQL_ID for an hour on one event.",
                    action="25_EBS master troubleshooter.",
                    caution="Pack licensed.",
                    privileges="SELECT on GV_$ACTIVE_SESSION_HISTORY",
                    notes="Requires Diagnostics Pack.",
                    sql="""DEFINE inst = 1
DEFINE sid  = 123
DEFINE minutes = 60

SELECT sample_time, sql_id, sql_plan_hash_value, session_state,
       NVL(event,'ON CPU') event, wait_class, blocking_session, p1, p2, p3
FROM   gv$active_session_history
WHERE  inst_id = &inst
AND    session_id = &sid
AND    sample_time > SYSDATE - &minutes/1440
ORDER BY sample_time;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="24_ash_by_wait_event.sql",
            category="08_SQL_Tuning",
            purpose="ASH filtered to one wait event",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack.",
            description="""When system event #1 is known (for example log file sync),
this shows which SQL/sessions contributed.""",
            queries=[
                Query(
                    title="ASH for one event",
                    what="Filters ASH by EVENT.",
                    columns="SQL_ID, MODULE, SAMPLES.",
                    interpret="Maps a wait event back to workload.",
                    problem="All log file sync samples from one chatty module.",
                    action="Fix that module's commit rate.",
                    caution="Pack licensed.",
                    privileges="SELECT on GV_$ACTIVE_SESSION_HISTORY",
                    notes="Requires Diagnostics Pack.",
                    sql="""DEFINE event_p = log file sync
DEFINE minutes = 60

SELECT sql_id, module, program, COUNT(*) samples
FROM   gv$active_session_history
WHERE  event = '&event_p'
AND    sample_time > SYSDATE - &minutes/1440
GROUP BY sql_id, module, program
ORDER BY samples DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="25_ash_by_module.sql",
            category="08_SQL_Tuning",
            purpose="ASH load by MODULE (EBS form / concurrent program)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack. Best EBS mapping when FND tables are not handy.",
            description="""Ranks modules by ASH samples.""",
            queries=[
                Query(
                    title="AAS by module",
                    what="Groups ASH by MODULE.",
                    columns="MODULE, SAMPLES, SQL_ID.",
                    interpret="EBS concurrent programs set MODULE to the program name.",
                    problem="One program owns AAS during the slowness.",
                    action="Folder 26 EBS performance / 25 troubleshooting.",
                    caution="Pack licensed.",
                    privileges="SELECT on GV_$ACTIVE_SESSION_HISTORY",
                    notes="Requires Diagnostics Pack.",
                    ebs="Critical for EBS",
                    sql="""DEFINE minutes = 60

SELECT NVL(module,'(none)') module, COUNT(*) samples,
       ROUND(COUNT(*)/(&minutes*60),2) AS aas
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - &minutes/1440
GROUP BY module
ORDER BY samples DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="26_ash_by_machine.sql",
            category="08_SQL_Tuning",
            purpose="ASH load by client machine",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack.",
            description="""Finds which app tier or concurrent node is generating DB time.""",
            queries=[
                Query(
                    title="AAS by machine",
                    what="Groups ASH by MACHINE.",
                    columns="MACHINE, SAMPLES, AAS.",
                    interpret="One apps node hot after a load-balancer failure is common.",
                    problem="All AAS from one machine that should be 1/N of the farm.",
                    action="Check that node's services / concurrent managers.",
                    caution="Pack licensed.",
                    privileges="SELECT on GV_$ACTIVE_SESSION_HISTORY",
                    notes="Requires Diagnostics Pack.",
                    ebs="Useful for EBS",
                    sql="""DEFINE minutes = 60

SELECT NVL(machine,'(none)') machine, COUNT(*) samples,
       ROUND(COUNT(*)/(&minutes*60),2) AS aas
FROM   gv$active_session_history
WHERE  sample_time > SYSDATE - &minutes/1440
GROUP BY machine
ORDER BY samples DESC;""",
                )
            ],
        ),
        Script(
            folder="08_SQL_Tuning",
            file_name="27_sql_execution_history.sql",
            category="08_SQL_Tuning",
            purpose="Historical executions from SQL Monitor and AWR for one SQL_ID",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: V$SQL_MONITOR / DBA_HIST_REPORTS SQL Monitor is Tuning Pack. DBA_HIST_SQLSTAT is Diagnostics Pack.",
            description="""Combines last executions (monitor) with AWR per-snap stats.""",
            queries=[
                Query(
                    title="Execution history for &sql_id",
                    what="SQL Monitor rows plus AWR deltas.",
                    columns="SQL_EXEC_START, STATUS, ELAPSED_S, SNAP ELA.",
                    interpret="Look for a step change in elapsed at a snap boundary (stats, volume, plan).",
                    problem="Last successful run 10 min, current 3 hours.",
                    action="Compare plans and binds between those times.",
                    caution="Pack licensed.",
                    privileges="SELECT on GV_$SQL_MONITOR, DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT",
                    notes="Tuning Pack (monitor) and Diagnostics Pack (AWR).",
                    sql="""DEFINE sql_id = 0w6u2qj2zn5hs

SELECT sql_exec_start, status, inst_id, sid,
       ROUND(elapsed_time/1e6,1) elapsed_s,
       ROUND(cpu_time/1e6,1) cpu_s,
       buffer_gets, disk_reads
FROM   gv$sql_monitor
WHERE  sql_id = '&sql_id'
ORDER BY sql_exec_start DESC;

SELECT TO_CHAR(sn.begin_interval_time,'DD-MON HH24:MI') snap_time,
       st.plan_hash_value,
       st.executions_delta execs,
       ROUND(st.elapsed_time_delta/NULLIF(st.executions_delta,0)/1e6,3) ela_per_exec_s
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  st.sql_id = '&sql_id'
AND    sn.begin_interval_time > SYSDATE - 7
ORDER BY sn.begin_interval_time;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
