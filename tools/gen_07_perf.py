#!/usr/bin/env python3
from _writer import Query, Script, write_many


LIC = "LICENSING: V$SQL is included with Enterprise Edition. DBA_HIST_* and ASH require Diagnostics Pack. SQL Tuning Advisor / SQL Monitor historical require Tuning Pack / Diagnostics Pack."


def top_sql(file_name, purpose, metric, order_expr, extra_cols, interpret, problem, action):
    return Script(
        folder="07_Performance_Tuning",
        file_name=file_name,
        category="07_Performance_Tuning",
        purpose=purpose,
        difficulty="Intermediate",
        production_use="YES",
        extra_header=LIC,
        description=f"""Ranks cursors in GV$SQL by {metric}. This is since the cursor
was loaded (not a wall-clock rate). Use AWR (08 / AWR scripts) for
a time-bounded ranking. Difference vs similar scripts: this file is
strictly ordered by {metric} so you do not mix units.""",
        queries=[
            Query(
                title=f"Top SQL by {metric}",
                what=f"Selects from GV$SQL ordered by {order_expr}.",
                columns=f"SQL_ID, {extra_cols}, PLAN_HASH_VALUE, MODULE, SQL_TEXT.",
                interpret=interpret,
                problem=problem,
                action=action,
                caution="Safe. GV$SQL can be large; FETCH FIRST limits cost. Do not flush the shared pool.",
                privileges="SELECT on GV_$SQL",
                notes="Does not require Diagnostics Pack.",
                sql=f"""SELECT
       sql_id,
       plan_hash_value,
       inst_id,
       child_number,
       parsing_schema_name,
       module,
       executions,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       ROUND(cpu_time/1e6,1) AS cpu_s,
       buffer_gets,
       disk_reads,
       rows_processed,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s,
       ROUND(buffer_gets/NULLIF(executions,0)) AS gets_per_exec,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    parsing_schema_name NOT IN ('SYS','SYSTEM')
ORDER BY {order_expr} DESC
FETCH FIRST 30 ROWS ONLY;""",
            )
        ],
    )


def scripts():
    return [
        top_sql(
            "01_top_sql_elapsed.sql",
            "Top SQL by cumulative elapsed time in the cursor cache",
            "elapsed time",
            "elapsed_time",
            "ELAPSED_S, ELA_PER_EXEC_S",
            "Elapsed includes waits. A SQL with huge elapsed and low executions is a long runner; huge elapsed and huge executions is a high-rate statement.",
            "One SQL_ID dominates elapsed and matches the incident window (check FIRST_LOAD_TIME / LAST_ACTIVE_TIME).",
            "Capture SQL_ID → 08_SQL_Tuning execution plan and waits. For history use 08 AWR top SQL.",
        ),
        top_sql(
            "02_top_sql_cpu.sql",
            "Top SQL by cumulative CPU time in the cursor cache",
            "CPU time",
            "cpu_time",
            "CPU_S",
            "CPU time is Oracle CPU, not host CPU. CPU ≈ elapsed means little wait. Elapsed >> CPU means wait-bound.",
            "CPU_S very high with a simple-looking SQL — usually a bad join order or function in a filter.",
            "Get the plan. Check cardinality. Do not increase CPU_COUNT as a first response.",
        ),
        top_sql(
            "03_top_sql_buffer_gets.sql",
            "Top SQL by buffer gets (logical I/O)",
            "buffer gets",
            "buffer_gets",
            "BUFFER_GETS, GETS_PER_EXEC",
            "Buffer gets measure logical I/O. Gets/exec in the millions is usually a plan problem even if the disk is quiet (cached full scan).",
            "GETS_PER_EXEC exploding vs a known good baseline (plan regression).",
            "Compare PLAN_HASH_VALUE history (14_sql_plan_regressions / 08).",
        ),
        top_sql(
            "04_top_sql_physical_reads.sql",
            "Top SQL by physical reads (disk I/O)",
            "physical reads",
            "disk_reads",
            "DISK_READS",
            "Physical reads may be direct path (serial FTS on large tables) or db file sequential/scattered.",
            "A reporting SQL flooding disks during OLTP hours.",
            "Reschedule, add partitioning/index, or use resource manager. Check 09 I/O waits.",
        ),
        top_sql(
            "05_top_sql_executions.sql",
            "Top SQL by execution count",
            "executions",
            "executions",
            "EXECUTIONS, ELA_PER_EXEC_S",
            "High executions with tiny ela/exec can still dominate DB time (EBS chatty Forms SQL). High executions with high ela/exec is worse.",
            "A SQL executed millions of times from a loop that should be set-based.",
            "Fix the application loop or add a bulk API. SQL tuning alone may not be enough.",
        ),
        top_sql(
            "06_top_sql_rows_processed.sql",
            "Top SQL by rows processed",
            "rows processed",
            "rows_processed",
            "ROWS_PROCESSED",
            "Rows processed is not rows returned to the client (it includes internal rows). Still useful to find heavy DML or unselective queries.",
            "Massive rows_processed on an UPDATE without a WHERE (or a bad bind).",
            "Confirm SQL text and binds. Check flashback/undo impact.",
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="07_sql_high_elapsed.sql",
            category="07_Performance_Tuning",
            purpose="SQL with high elapsed per execution (long runners, not just popular)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Unlike 01 (cumulative elapsed), this ranks by elapsed/execution
so a once-per-day 4-hour job surfaces. Use when 'one request is stuck'.""",
            extra_header="Difference vs 01_top_sql_elapsed.sql: 01 finds DB-time hogs; this finds slow individual executions.",
            queries=[
                Query(
                    title="Highest elapsed per execution",
                    what="Orders GV$SQL by elapsed_time/executions with a minimum elapsed floor.",
                    columns="SQL_ID, ELA_PER_EXEC_S, EXECUTIONS.",
                    interpret="Single-execution SQL with hours of elapsed is a concurrent program candidate.",
                    problem="ELA_PER_EXEC in thousands of seconds.",
                    action="Join to EBS request (25_EBS) if MODULE looks like a concurrent program.",
                    caution="Safe. Filter out SYS.",
                    privileges="SELECT on GV_$SQL",
                    sql="""SELECT
       sql_id,
       plan_hash_value,
       parsing_schema_name,
       module,
       executions,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,2) AS ela_per_exec_s,
       ROUND(cpu_time/NULLIF(executions,0)/1e6,2) AS cpu_per_exec_s,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    elapsed_time > 60*1e6
AND    parsing_schema_name NOT IN ('SYS','SYSTEM')
ORDER BY elapsed_time/executions DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="08_sql_high_cpu.sql",
            category="07_Performance_Tuning",
            purpose="SQL with high CPU per execution",
            difficulty="Intermediate",
            production_use="YES",
            description="""Per-execution CPU. Complements 02 (cumulative CPU).""",
            queries=[
                Query(
                    title="Highest CPU per execution",
                    what="Orders GV$SQL by cpu_time/executions.",
                    columns="SQL_ID, CPU_PER_EXEC_S.",
                    interpret="High CPU/exec with low disk reads = CPU-bound plan (functions, misestimate).",
                    problem="CPU/exec jumped after a stats gather (plan change).",
                    action="Compare plans (13/14).",
                    caution="Safe.",
                    privileges="SELECT on GV_$SQL",
                    sql="""SELECT
       sql_id,
       plan_hash_value,
       module,
       executions,
       ROUND(cpu_time/NULLIF(executions,0)/1e6,2) AS cpu_per_exec_s,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,2) AS ela_per_exec_s,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    cpu_time > 10*1e6
ORDER BY cpu_time/executions DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="09_sql_high_io.sql",
            category="07_Performance_Tuning",
            purpose="SQL with high physical I/O per execution",
            difficulty="Intermediate",
            production_use="YES",
            description="""Per-execution disk reads. Complements 04.""",
            queries=[
                Query(
                    title="Highest disk reads per execution",
                    what="Orders GV$SQL by disk_reads/executions.",
                    columns="SQL_ID, READS_PER_EXEC.",
                    interpret="Direct path reads on large FTS show up here.",
                    problem="Reads/exec in the millions on an OLTP SQL.",
                    action="Check 24_full_table_scans and the plan.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SQL",
                    sql="""SELECT
       sql_id,
       plan_hash_value,
       module,
       executions,
       ROUND(disk_reads/NULLIF(executions,0)) AS reads_per_exec,
       ROUND(buffer_gets/NULLIF(executions,0)) AS gets_per_exec,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 0
AND    disk_reads > 10000
ORDER BY disk_reads/executions DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="10_sql_excessive_executions.sql",
            category="07_Performance_Tuning",
            purpose="Very chatty SQL (high executions, not necessarily high elapsed)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Finds statements that execute extremely often. Typical EBS Forms
validation SQL. Different from 05 because a minimum executions floor
and ela/exec ceiling highlights 'death by a thousand cuts'.""",
            queries=[
                Query(
                    title="Chatty SQL",
                    what="High executions with small per-exec elapsed.",
                    columns="SQL_ID, EXECUTIONS, ELA_PER_EXEC_MS.",
                    interpret="These often need application caching or a bind/plan fix, not a bigger buffer cache.",
                    problem="Executions in tens of millions since startup from one module.",
                    action="Work with the developer. Consider result cache only if deterministic and licensed/appropriate.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SQL",
                    ebs="Useful for EBS",
                    sql="""SELECT
       sql_id,
       module,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e3,2) AS ela_per_exec_ms,
       ROUND(elapsed_time/1e6,1) AS elapsed_s,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  executions > 100000
ORDER BY executions DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="11_sql_poor_efficiency.sql",
            category="07_Performance_Tuning",
            purpose="SQL with terrible buffer gets per row (inefficient access)",
            difficulty="Advanced",
            production_use="YES",
            description="""Gets-per-row is a rough efficiency metric. High values mean the
engine touches many blocks to produce few rows (bad join, missing index,
or implicit conversion).""",
            queries=[
                Query(
                    title="Inefficient SQL by gets per row",
                    what="Orders GV$SQL by buffer_gets/rows_processed with guards.",
                    columns="SQL_ID, GETS_PER_ROW, GETS_PER_EXEC.",
                    interpret="Hundreds of gets/row on a multi-table join is a smoking gun.",
                    problem="Gets/row jumped after a plan change.",
                    action="Inspect the plan for nested loops on large row sources.",
                    caution="Safe. rows_processed = 0 statements are excluded.",
                    privileges="SELECT on GV_$SQL",
                    sql="""SELECT
       sql_id,
       plan_hash_value,
       executions,
       buffer_gets,
       rows_processed,
       ROUND(buffer_gets/NULLIF(rows_processed,0)) AS gets_per_row,
       ROUND(buffer_gets/NULLIF(executions,0)) AS gets_per_exec,
       SUBSTR(sql_text,1,180) AS sql_text
FROM   gv$sql
WHERE  rows_processed > 100
AND    buffer_gets > 100000
AND    parsing_schema_name NOT IN ('SYS','SYSTEM')
ORDER BY buffer_gets/NULLIF(rows_processed,0) DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="12_sql_plan_changes.sql",
            category="07_Performance_Tuning",
            purpose="SQL_IDs that currently have more than one plan hash in cache",
            difficulty="Advanced",
            production_use="YES",
            description="""Multiple PLAN_HASH_VALUE for one SQL_ID in GV$SQL means the
optimizer produced different plans (adaptive, binds, stats, degree).
This is a current-cache view. Historical regressions need AWR (14).""",
            extra_header="Difference vs 14_sql_plan_regressions.sql: this is cache-only and pack-free; 14 uses AWR.",
            queries=[
                Query(
                    title="SQL with multiple plans in cache",
                    what="Groups GV$SQL by SQL_ID having COUNT(DISTINCT plan_hash_value) > 1.",
                    columns="SQL_ID, PLAN_COUNT, PLANS.",
                    interpret="Different plans can be OK (adaptive). Compare elapsed/exec per plan_hash.",
                    problem="One plan_hash is 100x slower and still being used.",
                    action="Consider a SQL baseline (Tuning Pack / EE) after proving the good plan. See 08_SQL_Tuning.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SQL",
                    sql="""SELECT
       sql_id,
       COUNT(DISTINCT plan_hash_value) AS plan_count,
       COUNT(*) AS child_cursors,
       ROUND(SUM(elapsed_time)/1e6,1) AS elapsed_s
FROM   gv$sql
GROUP BY sql_id
HAVING COUNT(DISTINCT plan_hash_value) > 1
ORDER BY child_cursors DESC
FETCH FIRST 40 ROWS ONLY;

SELECT sql_id, plan_hash_value, inst_id, child_number,
       executions,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,4) AS ela_per_exec_s,
       buffer_gets
FROM   gv$sql
WHERE  sql_id = '&sql_id'
ORDER BY ela_per_exec_s DESC NULLS LAST;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="13_sql_plan_history.sql",
            category="07_Performance_Tuning",
            purpose="Plan history for one SQL_ID from AWR (DBA_HIST_SQLSTAT)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack required.",
            description="""Time series of PLAN_HASH_VALUE and elapsed/exec for a known SQL_ID.
Use after a user says 'it got slow yesterday'.""",
            queries=[
                Query(
                    title="AWR plan history for &sql_id",
                    what="Reads DBA_HIST_SQLSTAT joined to snapshots.",
                    columns="SNAP_TIME, PLAN_HASH_VALUE, ELA_PER_EXEC, EXECS.",
                    interpret="A new PLAN_HASH_VALUE coinciding with a runtime jump is a regression.",
                    problem="Plan flip after autostats or a bind change.",
                    action="08_SQL_Tuning baselines / profiles. Restore stats only with a plan.",
                    caution="Pack licensed. Bind the SQL_ID.",
                    privileges="SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""DEFINE sql_id = 0w6u2qj2zn5hs

SELECT
       TO_CHAR(sn.begin_interval_time, 'DD-MON HH24:MI') AS snap_time,
       st.instance_number,
       st.plan_hash_value,
       st.executions_delta AS execs,
       ROUND(st.elapsed_time_delta/NULLIF(st.executions_delta,0)/1e6,4) AS ela_per_exec_s,
       ROUND(st.buffer_gets_delta/NULLIF(st.executions_delta,0)) AS gets_per_exec,
       ROUND(st.disk_reads_delta/NULLIF(st.executions_delta,0)) AS reads_per_exec
FROM   dba_hist_sqlstat st
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
WHERE  st.sql_id = '&sql_id'
AND    sn.begin_interval_time > SYSDATE - 14
ORDER BY sn.begin_interval_time, st.instance_number;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="14_sql_plan_regressions.sql",
            category="07_Performance_Tuning",
            purpose="Detect SQL_IDs whose elapsed/exec worsened across plans in AWR",
            difficulty="Advanced",
            production_use="YES",
            extra_header="LICENSING: Diagnostics Pack required.",
            description="""Compares average elapsed/exec per plan_hash over a recent window
and flags SQL with a wide gap between best and worst plan.""",
            queries=[
                Query(
                    title="Plan performance spread last 7 days",
                    what="Aggregates DBA_HIST_SQLSTAT by SQL_ID and PLAN_HASH_VALUE.",
                    columns="SQL_ID, PLAN_HASH, ELA_PER_EXEC, EXECS.",
                    interpret="A plan with few execs and huge ela can be an outlier bind.",
                    problem="Worst plan 10x+ the best plan with material execution counts.",
                    action="Pin the good plan (baseline) after validation.",
                    caution="Pack licensed. Can be heavy — 7 day window.",
                    privileges="SELECT on DBA_HIST_SQLSTAT, DBA_HIST_SNAPSHOT",
                    notes="Requires Diagnostics Pack.",
                    sql="""WITH p AS (
       SELECT
              st.sql_id,
              st.plan_hash_value,
              SUM(st.executions_delta) execs,
              SUM(st.elapsed_time_delta)/1e6 ela_s
       FROM   dba_hist_sqlstat st
       JOIN   dba_hist_snapshot sn
              ON sn.snap_id = st.snap_id AND sn.dbid = st.dbid AND sn.instance_number = st.instance_number
       WHERE  sn.begin_interval_time > SYSDATE - 7
       GROUP BY st.sql_id, st.plan_hash_value
       HAVING SUM(st.executions_delta) > 0
)
SELECT
       sql_id,
       COUNT(*) AS plans,
       ROUND(MIN(ela_s/execs),4) AS best_ela_exec_s,
       ROUND(MAX(ela_s/execs),4) AS worst_ela_exec_s,
       ROUND(MAX(ela_s/execs)/NULLIF(MIN(ela_s/execs),0),1) AS regression_factor,
       SUM(execs) AS total_execs
FROM   p
GROUP BY sql_id
HAVING COUNT(*) > 1
AND    MAX(ela_s/execs) > MIN(ela_s/execs) * 5
ORDER BY regression_factor DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="15_sql_child_cursors.sql",
            category="07_Performance_Tuning",
            purpose="Child cursor explosion and reason codes",
            difficulty="Advanced",
            production_use="YES",
            description="""Too many child cursors waste shared pool and cause hard parse /
mutex waits. V$SQL_SHARED_CURSOR shows why children were not shared.""",
            queries=[
                Query(
                    title="SQL with many children and mismatch reasons",
                    what="Counts children in GV$SQL and samples V$SQL_SHARED_CURSOR.",
                    columns="SQL_ID, CHILDREN, REASON FLAGS.",
                    interpret="BIND_MISMATCH, AUTH_CHECK_MISMATCH, OPTIMIZER_MISMATCH are common. EBS NLS differences also split cursors.",
                    problem="Hundreds of children for one SQL_ID plus 'cursor: pin S wait on X'.",
                    action="Fix the mismatch (binds, NLS, optimizer settings). Do not flush shared pool in production as a habit.",
                    caution="Safe. V$SQL_SHARED_CURSOR can be wide — select known reason columns.",
                    privileges="SELECT on GV_$SQL, V_$SQL_SHARED_CURSOR",
                    sql="""SELECT sql_id, COUNT(*) children, COUNT(DISTINCT plan_hash_value) plans,
       SUM(parse_calls) parse_calls, ROUND(SUM(sharable_mem)/1024/1024,1) sharable_mb
FROM   gv$sql
GROUP BY sql_id
HAVING COUNT(*) > 20
ORDER BY children DESC
FETCH FIRST 30 ROWS ONLY;

SELECT
       sql_id,
       child_number,
       bind_mismatch,
       optimizer_mismatch,
       auth_check_mismatch,
       language_mismatch,
       outline_mismatch,
       translation_mismatch,
       row_level_sec_mismatch
FROM   v$sql_shared_cursor
WHERE  sql_id = '&sql_id';""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="16_bind_variables.sql",
            category="07_Performance_Tuning",
            purpose="Inspect bind values captured for a SQL_ID",
            difficulty="Advanced",
            production_use="YES",
            description="""V$SQL_BIND_CAPTURE shows peeked/captured binds. Peeking + skew
is a top cause of intermittent bad plans in EBS.""",
            extra_header="LICENSING: V$SQL_BIND_CAPTURE is EE dictionary. AWR bind capture history is Diagnostics Pack (DBA_HIST_SQLBIND).",
            queries=[
                Query(
                    title="Captured binds for &sql_id",
                    what="Reads V$SQL_BIND_CAPTURE.",
                    columns="NAME, DATATYPE_STRING, VALUE_STRING, LAST_CAPTURED.",
                    interpret="VALUE_STRING may be truncated. DATATYPE mismatches cause implicit conversion and index suppression.",
                    problem="A bind of '%' or NULL changing cardinality.",
                    action="Check histograms / bind-aware cursor sharing (adaptive cursor sharing).",
                    caution="Safe. Binds may contain sensitive data — handle output as confidential.",
                    privileges="SELECT on V_$SQL_BIND_CAPTURE",
                    sql="""DEFINE sql_id = 0w6u2qj2zn5hs

SELECT
       sql_id,
       child_number,
       name,
       position,
       datatype_string,
       value_string,
       last_captured
FROM   v$sql_bind_capture
WHERE  sql_id = '&sql_id'
ORDER BY child_number, position;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="17_hard_parsing.sql",
            category="07_Performance_Tuning",
            purpose="Hard parse rate from V$SYSSTAT",
            difficulty="Advanced",
            production_use="YES",
            description="""Hard parses consume shared pool latches/mutexes and CPU. A sudden
jump usually means literal SQL or a shared pool flush.""",
            queries=[
                Query(
                    title="Parse statistics (instance)",
                    what="Reads parse counts from GV$SYSSTAT.",
                    columns="STAT_NAME, VALUE.",
                    interpret="Hard parses should be a tiny fraction of total parses. Compare to a baseline; the absolute value since startup is not a rate.",
                    problem="Hard parses growing quickly (take two snapshots 60s apart).",
                    action="Find literal SQL (18/20). Check for recent FLUSH SHARED_POOL.",
                    caution="Safe. Two-snapshot rate is more meaningful than a single sample.",
                    privileges="SELECT on GV_$SYSSTAT",
                    sql="""SELECT inst_id, name, value
FROM   gv$sysstat
WHERE  name IN (
         'parse count (total)',
         'parse count (hard)',
         'parse count (failures)',
         'parse time cpu',
         'parse time elapsed',
         'session cursor cache hits',
         'session cursor cache count'
       )
ORDER BY inst_id, name;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="18_soft_parsing.sql",
            category="07_Performance_Tuning",
            purpose="Soft parse vs execute ratio",
            difficulty="Advanced",
            production_use="YES",
            description="""Even soft parses cost. The ideal is parse once, execute many
(session cursor cache / bind SQL).""",
            queries=[
                Query(
                    title="Parse to execute ratio",
                    what="Computes parse/execute from V$SYSSTAT.",
                    columns="PARSE_TOTAL, EXECUTIONS, PARSE_PER_EXEC.",
                    interpret="Parse/exec near 1 means almost no cursor reuse (chatty app or missing binds).",
                    problem="Parse/exec > 0.8 on an OLTP EBS instance.",
                    action="Session cursor cache, bind variables, avoid invalidations (23).",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSSTAT",
                    sql="""SELECT
       inst_id,
       MAX(CASE WHEN name = 'parse count (total)' THEN value END) AS parse_total,
       MAX(CASE WHEN name = 'parse count (hard)' THEN value END) AS parse_hard,
       MAX(CASE WHEN name = 'execute count' THEN value END) AS execute_count,
       ROUND(MAX(CASE WHEN name = 'parse count (total)' THEN value END)
             / NULLIF(MAX(CASE WHEN name = 'execute count' THEN value END),0), 3) AS parse_per_exec,
       ROUND(MAX(CASE WHEN name = 'parse count (hard)' THEN value END)
             / NULLIF(MAX(CASE WHEN name = 'parse count (total)' THEN value END),0), 3) AS hard_parse_ratio
FROM   gv$sysstat
WHERE  name IN ('parse count (total)','parse count (hard)','execute count')
GROUP BY inst_id
ORDER BY inst_id;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="19_parse_ratio.sql",
            category="07_Performance_Tuning",
            purpose="Human-readable parse ratios with alert bands",
            difficulty="Intermediate",
            production_use="YES",
            description="""Wraps 17/18 into alert levels for a health check.""",
            queries=[
                Query(
                    title="Parse health",
                    what="Same math as 18 with CASE bands.",
                    columns="HARD_PARSE_RATIO, PARSE_PER_EXEC, ALERT.",
                    interpret="Hard parse ratio > 0.20 is WARNING on OLTP; > 0.40 CRITICAL.",
                    problem="CRITICAL after a shared pool flush or login storm of unique SQL.",
                    action="See 20/22. Do not increase shared pool blindly.",
                    caution="Safe. Ratios since startup can hide a recent incident — take a delta.",
                    privileges="SELECT on GV_$SYSSTAT",
                    sql="""WITH s AS (
       SELECT inst_id, name, value FROM gv$sysstat
       WHERE  name IN ('parse count (total)','parse count (hard)','execute count')
)
SELECT
       inst_id,
       ROUND(hardp/NULLIF(totp,0),3) AS hard_parse_ratio,
       ROUND(totp/NULLIF(execs,0),3) AS parse_per_exec,
       CASE
         WHEN hardp/NULLIF(totp,0) > 0.40 THEN 'CRITICAL'
         WHEN hardp/NULLIF(totp,0) > 0.20 THEN 'WARNING'
         WHEN hardp/NULLIF(totp,0) > 0.10 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   (
       SELECT inst_id,
              MAX(CASE WHEN name='parse count (hard)' THEN value END) hardp,
              MAX(CASE WHEN name='parse count (total)' THEN value END) totp,
              MAX(CASE WHEN name='execute count' THEN value END) execs
       FROM   s
       GROUP BY inst_id
);""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="20_library_cache.sql",
            category="07_Performance_Tuning",
            purpose="Library cache hit ratios and lock/pin counts",
            difficulty="Advanced",
            production_use="YES",
            description="""V$LIBRARYCACHE namespace health. Low get/pinhitratio plus
locks/pins waits indicate parse or invalidation storms.""",
            queries=[
                Query(
                    title="Library cache namespaces",
                    what="Reads GV$LIBRARYCACHE.",
                    columns="NAMESPACE, GETHITRATIO, PINHITRATIO, RELOADS, INVALIDATIONS.",
                    interpret="SQL AREA invalidations/reloads should be low. High RELOADS means objects are aging out or being invalidated.",
                    problem="SQL AREA GETHITRATIO < 0.90 on OLTP or INVALIDATIONS climbing.",
                    action="Find invalidation source (DDL, stats with invalidate, grants). See 23.",
                    caution="Safe.",
                    privileges="SELECT on GV_$LIBRARYCACHE",
                    sql="""SELECT
       inst_id,
       namespace,
       gets,
       gethits,
       ROUND(gethitratio,3) AS gethitratio,
       pins,
       pinhits,
       ROUND(pinhitratio,3) AS pinhitratio,
       reloads,
       invalidations
FROM   gv$librarycache
ORDER BY inst_id, namespace;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="21_shared_pool.sql",
            category="07_Performance_Tuning",
            purpose="Shared pool free memory, advice, and reserved list",
            difficulty="Advanced",
            production_use="YES",
            description="""ORA-04031 investigation starting point. Complements 11_Memory/04
and 30_Advanced ORA-04031 playbook.""",
            queries=[
                Query(
                    title="Shared pool memory and reserved area",
                    what="Reads V$SGASTAT, V$SHARED_POOL_RESERVED, V$SHARED_POOL_ADVICE.",
                    columns="BYTES, REQUEST_FAILURES, LAST_FAILURE_SIZE.",
                    interpret="REQUEST_FAILURES > 0 is a 4031 precursor. Advice shows estimated extra hits if you grow the pool — not a mandate.",
                    problem="REQUEST_FAILURES increasing or free memory fragmented (failed requests for small sizes).",
                    action="Find large unshared SQL. Do not FLUSH SHARED_POOL during the incident (makes it worse). See 30/08.",
                    caution="Safe. Shared pool advice is statistical.",
                    privileges="SELECT on GV_$SGASTAT, GV_$SHARED_POOL_RESERVED, GV_$SHARED_POOL_ADVICE",
                    sql="""SELECT inst_id, pool, name, ROUND(bytes/1024/1024,1) mb
FROM   gv$sgastat
WHERE  pool = 'shared pool'
AND    (
         name IN ('free memory','sql area','library cache','KGLH0','KGLHD')
         OR bytes > 50*1024*1024
       )
ORDER BY inst_id, bytes DESC;

SELECT inst_id, free_space, avg_free_size, used_space, request_failures, last_failure_size, last_miss_size
FROM   gv$shared_pool_reserved;

SELECT inst_id, shared_pool_size_for_estimate, estd_lc_size, estd_lc_memory_objects, estd_lc_time_saved
FROM   gv$shared_pool_advice
ORDER BY inst_id, shared_pool_size_for_estimate;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="22_cursor_usage.sql",
            category="07_Performance_Tuning",
            purpose="Open cursors per session vs open_cursors parameter",
            difficulty="Intermediate",
            production_use="YES",
            description="""ORA-01000 is open cursor leaks (typically Java/Forms).""",
            queries=[
                Query(
                    title="Open cursors vs limit",
                    what="Reads V$SYSSTAT opened cursors current and V$OPEN_CURSOR counts.",
                    columns="SID, OPEN_CURSORS, PARAMETER.",
                    interpret="A session near open_cursors is about to fail. High cache cursors is OK (session cursor cache).",
                    problem="One APPS session with thousands of open cursors.",
                    action="Fix the application leak. Raising open_cursors hides the leak.",
                    caution="Safe. V$OPEN_CURSOR can be large.",
                    privileges="SELECT on GV_$SESSION, GV_$SESSTAT, GV_$STATNAME, V_$PARAMETER",
                    sql="""SELECT name, value FROM v$parameter WHERE name IN ('open_cursors','session_cached_cursors');

SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       st.value AS open_cursors
FROM   gv$session s
JOIN   gv$sesstat st ON st.inst_id = s.inst_id AND st.sid = s.sid
JOIN   gv$statname sn ON sn.inst_id = st.inst_id AND sn.statistic# = st.statistic#
WHERE  sn.name = 'opened cursors current'
ORDER BY st.value DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="23_invalidations.sql",
            category="07_Performance_Tuning",
            purpose="Cursor invalidations and recent DDL that may have caused them",
            difficulty="Advanced",
            production_use="YES",
            description="""High invalidations follow statistics jobs, GRANTs, or ALTER TABLE.
This script shows library cache invalidations and recent object DDL.""",
            queries=[
                Query(
                    title="Invalidations and recent DDL",
                    what="V$LIBRARYCACHE.INVALIDATIONS plus recent LAST_DDL_TIME.",
                    columns="INVALIDATIONS, OWNER, OBJECT_NAME, LAST_DDL_TIME.",
                    interpret="A stats job that invalidates (default DBMS_STATS) can flip plans cluster-wide.",
                    problem="Invalidations spike aligned with an auto-stats window.",
                    action="Use NO_INVALIDATE carefully (understand the tradeoff). Avoid mid-day DDL.",
                    caution="Safe.",
                    privileges="SELECT on GV_$LIBRARYCACHE, DBA_OBJECTS",
                    sql="""SELECT inst_id, namespace, invalidations, reloads
FROM   gv$librarycache
WHERE  invalidations > 0
ORDER BY invalidations DESC;

SELECT owner, object_type, object_name, last_ddl_time
FROM   dba_objects
WHERE  last_ddl_time > SYSDATE - 1
AND    owner NOT IN ('SYS','SYSTEM')
AND    object_type IN ('TABLE','INDEX','PACKAGE','PACKAGE BODY','VIEW','SYNONYM')
ORDER BY last_ddl_time DESC
FETCH FIRST 80 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="24_full_table_scans.sql",
            category="07_Performance_Tuning",
            purpose="SQL currently doing or recently doing full table scans",
            difficulty="Advanced",
            production_use="YES",
            description="""Uses V$SQL_PLAN for TABLE ACCESS FULL in cache. Not every FTS is
bad (small tables, reporting). Filter by cost/bytes.""",
            extra_header="V$SQL_PLAN is EE and pack-free. Historical plans in DBA_HIST_SQL_PLAN need Diagnostics Pack.",
            queries=[
                Query(
                    title="FTS operations in cached plans",
                    what="Joins V$SQL_PLAN to V$SQL for TABLE ACCESS FULL.",
                    columns="SQL_ID, OBJECT_OWNER, OBJECT_NAME, CARDINALITY, BYTES.",
                    interpret="FTS on a multi-GB table in an OLTP module is the problem set.",
                    problem="Scattered read waits + FTS on a large transaction table.",
                    action="Confirm predicates and indexes. Check implicit conversions.",
                    caution="Safe. Plan table can be large — limited fetch.",
                    privileges="SELECT on V_$SQL_PLAN, V_$SQL",
                    sql="""SELECT
       p.sql_id,
       p.plan_hash_value,
       p.object_owner,
       p.object_name,
       p.cardinality,
       p.bytes,
       p.cost,
       ROUND(s.elapsed_time/1e6,1) AS elapsed_s,
       SUBSTR(s.sql_text,1,140) AS sql_text
FROM   v$sql_plan p
JOIN   v$sql s ON s.sql_id = p.sql_id AND s.plan_hash_value = p.plan_hash_value AND s.child_number = p.child_number
WHERE  p.operation = 'TABLE ACCESS'
AND    p.options LIKE '%FULL%'
AND    p.object_owner NOT IN ('SYS','SYSTEM')
ORDER BY p.bytes DESC NULLS LAST
FETCH FIRST 40 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="25_index_usage.sql",
            category="07_Performance_Tuning",
            purpose="Index usage from DBA_INDEX_USAGE (12.2+) or monitoring",
            difficulty="Advanced",
            production_use="YES",
            description="""12.2+ DBA_INDEX_USAGE tracks access when _iut_stat / index usage
tracking is available (19c has DBA_INDEX_USAGE). Older approach is
ALTER INDEX MONITORING USAGE (not enabled here).""",
            extra_header="Oracle 19c DBA_INDEX_USAGE. Absence of usage is not proof an index is unused (feature window, reset).",
            queries=[
                Query(
                    title="Index usage tracking",
                    what="Reads DBA_INDEX_USAGE ordered by total_access_count.",
                    columns="NAME, TOTAL_ACCESS_COUNT, TOTAL_EXEC_COUNT, LAST_USED.",
                    interpret="Zero access over a full business cycle is a drop candidate — still verify uniqueness/FK.",
                    problem="A huge index never used (space waste) vs a critical unique index used rarely.",
                    action="Do not drop unique/PK/FK-supporting indexes. See 27.",
                    caution="Safe. Tracking is sampled / since last reset.",
                    privileges="SELECT on DBA_INDEX_USAGE, DBA_INDEXES",
                    notes="Oracle 19c (DBA_INDEX_USAGE).",
                    sql="""SELECT
       owner,
       name,
       total_access_count,
       total_exec_count,
       total_rows_returned,
       last_used
FROM   dba_index_usage
ORDER BY total_access_count DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="26_missing_indexes.sql",
            category="07_Performance_Tuning",
            purpose="Heuristic missing-index suspects (unindexed FK + FTS), not a magic advisor",
            difficulty="Advanced",
            production_use="YES",
            extra_header="SQL Access Advisor requires Tuning Pack and is not auto-run here. This script only lists heuristics.",
            description="""There is no safe 'create these indexes' list. This combines
unindexed FK (from 05_Objects/07) with large FTS objects as suspects
for a human to review.""",
            queries=[
                Query(
                    title="Suspect objects appearing in FTS",
                    what="Distinct large objects from V$SQL_PLAN FULL plus reminder to check FKs.",
                    columns="OBJECT_OWNER, OBJECT_NAME, SQL_COUNT.",
                    interpret="Frequency in plans != missing index. Always open the SQL.",
                    problem="A custom table in many FTS plans.",
                    action="Manual design. Do not create 10 indexes from this list.",
                    caution="Safe. Not a substitute for SQL Tuning Advisor (licensed).",
                    privileges="SELECT on V_$SQL_PLAN",
                    sql="""SELECT
       object_owner,
       object_name,
       COUNT(DISTINCT sql_id) AS sql_count,
       ROUND(MAX(bytes)/1024/1024,1) AS max_est_mb
FROM   v$sql_plan
WHERE  operation = 'TABLE ACCESS'
AND    options LIKE '%FULL%'
AND    object_owner NOT IN ('SYS','SYSTEM')
GROUP BY object_owner, object_name
ORDER BY sql_count DESC, max_est_mb DESC
FETCH FIRST 40 ROWS ONLY;

PROMPT Also run ../05_Objects/07_foreign_keys.sql for unindexed FK suspects.""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="27_unused_indexes.sql",
            category="07_Performance_Tuning",
            purpose="Indexes with no usage tracking hits (candidates only)",
            difficulty="Advanced",
            production_use="YES",
            description="""Left join DBA_INDEXES to DBA_INDEX_USAGE. Unused != droppable.
Unique, PK, and FK-supporting indexes stay.""",
            queries=[
                Query(
                    title="Indexes without usage rows",
                    what="Finds non-unique indexes with no DBA_INDEX_USAGE row or zero access.",
                    columns="OWNER, INDEX_NAME, TABLE_NAME, SIZE_MB.",
                    interpret="Run this after a full month of tracking. Month-end indexes may look unused mid-month.",
                    problem="Very large unused non-unique index on a hot table (DML tax).",
                    action="Mark invisible first (19c) in a change window, then drop later. Generated only.",
                    caution="WARNING: DROP/INVISIBLE generated only. Invisible indexes still require maintenance for DML.",
                    privileges="SELECT on DBA_INDEXES, DBA_INDEX_USAGE, DBA_SEGMENTS, DBA_CONSTRAINTS",
                    notes="Oracle 19c.",
                    sql="""SELECT
       i.owner,
       i.index_name,
       i.table_name,
       i.uniqueness,
       ROUND(s.bytes/1024/1024,1) AS size_mb,
       u.total_access_count,
       u.last_used
FROM   dba_indexes i
JOIN   dba_segments s
       ON s.owner = i.owner AND s.segment_name = i.index_name AND s.segment_type LIKE 'INDEX%'
LEFT JOIN dba_index_usage u
       ON u.owner = i.owner AND u.name = i.index_name
WHERE  i.owner NOT IN ('SYS','SYSTEM')
AND    i.uniqueness = 'NONUNIQUE'
AND    i.index_type = 'NORMAL'
AND    NVL(u.total_access_count,0) = 0
AND    s.bytes > 100*1024*1024
AND    NOT EXISTS (
         SELECT 1 FROM dba_constraints c
         WHERE  c.owner = i.table_owner
         AND    c.table_name = i.table_name
         AND    c.constraint_type IN ('P','U')
         AND    c.index_name = i.index_name
       )
ORDER BY s.bytes DESC
FETCH FIRST 40 ROWS ONLY;

-- WARNING: Review carefully before executing.
-- SELECT 'ALTER INDEX "'||owner||'"."'||index_name||'" INVISIBLE;' FROM ... ;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="28_statistics_status.sql",
            category="07_Performance_Tuning",
            purpose="Stats freshness summary by schema",
            difficulty="Intermediate",
            production_use="YES",
            description="""Counts tables with/without stats and last analyzed age.""",
            queries=[
                Query(
                    title="Statistics coverage by owner",
                    what="Aggregates DBA_TABLES last_analyzed.",
                    columns="OWNER, TABLES, WITH_STATS, STALE_30D.",
                    interpret="EBS product schemas should be gathered with the approved EBS stats procedure, not ad-hoc schema stats during peak.",
                    problem="A large transactional schema with last_analyzed months ago OR stats gathered mid-day causing parse storms.",
                    action="Use FND_STATS / Concurrent Gather Schema Statistics for EBS. See 30.",
                    caution="Safe.",
                    privileges="SELECT on DBA_TABLES",
                    ebs="Useful for EBS",
                    sql="""SELECT
       owner,
       COUNT(*) AS tables,
       SUM(CASE WHEN last_analyzed IS NULL THEN 1 ELSE 0 END) AS no_stats,
       SUM(CASE WHEN last_analyzed < SYSDATE - 30 THEN 1 ELSE 0 END) AS older_than_30d,
       MAX(last_analyzed) AS newest_stats
FROM   dba_tables
WHERE  owner NOT IN ('SYS','SYSTEM','XDB')
AND    temporary = 'N'
GROUP BY owner
ORDER BY no_stats DESC, owner;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="29_stale_statistics.sql",
            category="07_Performance_Tuning",
            purpose="Objects marked stale in DBA_TAB_STATISTICS",
            difficulty="Intermediate",
            production_use="YES",
            description="""STALE_STATS = YES means monitoring thinks enough DML occurred.
Stale is a hint, not a command to gather now.""",
            queries=[
                Query(
                    title="Stale table statistics",
                    what="Reads DBA_TAB_STATISTICS where STALE_STATS = YES.",
                    columns="OWNER, TABLE_NAME, STALE_STATS, LAST_ANALYZED, NUM_ROWS.",
                    interpret="A table can be stale and still have a good plan. Gathering can make things worse if it invalidates a stable plan.",
                    problem="Critical table stale after a huge data load and plans are clearly wrong (cardinality off by orders of magnitude).",
                    action="Gather for that table in a window with the EBS-approved method. Avoid GATHER_SCHEMA_STATS cascade mid-day.",
                    caution="Safe to query. DBMS_STATS is a change and is not executed.",
                    privileges="SELECT on DBA_TAB_STATISTICS",
                    sql="""SELECT
       owner,
       table_name,
       partition_name,
       stale_stats,
       last_analyzed,
       num_rows,
       sample_size
FROM   dba_tab_statistics
WHERE  stale_stats = 'YES'
AND    owner NOT IN ('SYS','SYSTEM')
AND    object_type = 'TABLE'
ORDER BY last_analyzed NULLS FIRST, owner, table_name
FETCH FIRST 80 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="30_optimizer_statistics.sql",
            category="07_Performance_Tuning",
            purpose="Optimizer-related parameters and stats job status",
            difficulty="Advanced",
            production_use="YES",
            description="""Shows optimizer parameters and autostats job state. EBS often
disables default autostats in favor of FND_STATS.""",
            queries=[
                Query(
                    title="Optimizer parameters and auto stats job",
                    what="V$PARAMETER optimizer% plus DBA_AUTOTASK_CLIENT.",
                    columns="NAME, VALUE, CLIENT_NAME, STATUS.",
                    interpret="optimizer_dynamic_sampling, optimizer_index_cost_adj (legacy EBS settings), and adaptive features affect plans.",
                    problem="Autostats running on a large EBS schema during peak contrary to site standard.",
                    action="Align with the EBS MOS notes for your release. Do not flip adaptive features mid-incident.",
                    caution="Safe. Changing optimizer parameters is a major change.",
                    privileges="SELECT on V_$PARAMETER, DBA_AUTOTASK_CLIENT, DBA_AUTOTASK_JOB_HISTORY",
                    ebs="Critical for EBS",
                    sql="""SELECT name, display_value, isdefault
FROM   v$parameter
WHERE  name LIKE 'optimizer%'
OR     name IN ('statistics_level','cursor_sharing','query_rewrite_enabled')
ORDER BY name;

SELECT client_name, status, consumer_group, window_group
FROM   dba_autotask_client;

SELECT client_name, job_name, job_status, job_start_time, job_duration
FROM   dba_autotask_job_history
WHERE  job_start_time > SYSDATE - 7
ORDER BY job_start_time DESC;""",
                )
            ],
        ),
        Script(
            folder="07_Performance_Tuning",
            file_name="31_histogram_information.sql",
            category="07_Performance_Tuning",
            purpose="Histograms on columns for a table (skew / bind peeking)",
            difficulty="Advanced",
            production_use="YES",
            description="""Histograms drive bind-sensitive plans. Too many FREQUENCY
histograms on EBS columns can cause unstable plans.""",
            queries=[
                Query(
                    title="Column histograms for one table",
                    what="Reads DBA_TAB_COL_STATISTICS for &owner &table.",
                    columns="COLUMN_NAME, HISTOGRAM, NUM_DISTINCT, DENSITY, LAST_ANALYZED.",
                    interpret="HISTOGRAM NONE vs FREQUENCY vs HYBRID (12c+). HEIGHT BALANCED is legacy.",
                    problem="A bind-peeked column with a FREQUENCY histogram and a popular value.",
                    action="Consider locking stats or a SQL baseline rather than dropping all histograms.",
                    caution="Safe.",
                    privileges="SELECT on DBA_TAB_COL_STATISTICS, DBA_HISTOGRAMS",
                    sql="""DEFINE owner_p = GL
DEFINE table_p = GL_JE_LINES

SELECT
       column_name,
       num_distinct,
       density,
       histogram,
       num_buckets,
       last_analyzed,
       sample_size,
       notes
FROM   dba_tab_col_statistics
WHERE  owner = '&owner_p'
AND    table_name = '&table_p'
ORDER BY column_name;

SELECT column_name, endpoint_number, endpoint_value, endpoint_actual_value
FROM   dba_tab_histograms
WHERE  owner = '&owner_p'
AND    table_name = '&table_p'
AND    ROWNUM <= 200
ORDER BY column_name, endpoint_number;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
