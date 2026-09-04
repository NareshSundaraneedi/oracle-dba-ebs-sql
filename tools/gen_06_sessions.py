#!/usr/bin/env python3
from _writer import Query, Script, write_many


def scripts():
    return [
        Script(
            folder="06_Sessions_Processes",
            file_name="01_all_sessions.sql",
            category="06_Sessions_Processes",
            purpose="List all sessions with instance, user, program, and status",
            difficulty="Basic",
            production_use="YES",
            description="""Cluster-wide session inventory (GV$SESSION). Use filters in later
scripts for active/inactive. This is the baseline 'who is connected'.""",
            queries=[
                Query(
                    title="All sessions",
                    what="Reads GV$SESSION excluding idle background noise optionally.",
                    columns="INST_ID, SID, SERIAL#, USERNAME, STATUS, PROGRAM, MACHINE, LOGON_TIME.",
                    interpret="BACKGROUND usernames are NULL. USER sessions have USERNAME set.",
                    problem="Session count near the SESSIONS parameter (see 02_Database_Administration/13).",
                    action="Identify connection leaks by MACHINE/PROGRAM (scripts 06-08).",
                    caution="Safe. Output can be large on EBS (Forms + concurrent + SSO).",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       inst_id,
       sid,
       serial#,
       username,
       status,
       type,
       program,
       module,
       action,
       machine,
       service_name,
       logon_time,
       sql_id,
       event,
       last_call_et
FROM   gv$session
ORDER BY inst_id, username, sid;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="02_active_sessions.sql",
            category="06_Sessions_Processes",
            purpose="Sessions currently ACTIVE (on CPU or waiting)",
            difficulty="Basic",
            production_use="YES",
            description="""ACTIVE means the session is inside a database call. This is the
first view during a 'database is slow' call. Pair with wait event.""",
            queries=[
                Query(
                    title="Active user sessions",
                    what="Filters GV$SESSION STATUS=ACTIVE TYPE=USER.",
                    columns="SID, SQL_ID, EVENT, WAIT_CLASS, SECONDS_IN_WAIT, MODULE.",
                    interpret="Many sessions on the same EVENT is a system problem. One session on CPU with high LAST_CALL_ET is a heavy SQL.",
                    problem="Dozens of ACTIVE sessions on enq: TX or log file sync.",
                    action="Follow 09_Wait_Events and 10_Locks_Blocking based on EVENT.",
                    caution="Safe. On RAC always use GV$.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       inst_id,
       sid,
       serial#,
       username,
       machine,
       program,
       module,
       action,
       sql_id,
       prev_sql_id,
       event,
       wait_class,
       state,
       seconds_in_wait,
       last_call_et,
       blocking_session,
       blocking_instance
FROM   gv$session
WHERE  status = 'ACTIVE'
AND    type   = 'USER'
ORDER BY last_call_et DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="03_inactive_sessions.sql",
            category="06_Sessions_Processes",
            purpose="INACTIVE sessions and how long they have been idle",
            difficulty="Basic",
            production_use="YES",
            description="""INACTIVE Forms/Java sessions holding locks are a classic EBS
issue (user left a form open). LAST_CALL_ET is seconds since last call.""",
            queries=[
                Query(
                    title="Idle user sessions",
                    what="STATUS=INACTIVE user sessions ordered by idle time.",
                    columns="SID, USERNAME, LAST_CALL_ET, MODULE, MACHINE.",
                    interpret="LAST_CALL_ET of many hours plus a lock (see 10) means a forgotten form.",
                    problem="Inactive session blocking others (blocking_session points here from active waiters).",
                    action="Contact the user. Generate disconnect if policy allows — 17_generate_disconnect_session.sql.",
                    caution="Safe. Killing inactive sessions drops unsaved Forms work.",
                    privileges="SELECT on GV_$SESSION",
                    ebs="Critical for EBS",
                    sql="""SELECT
       inst_id,
       sid,
       serial#,
       username,
       osuser,
       machine,
       program,
       module,
       status,
       last_call_et,
       ROUND(last_call_et/3600,2) AS idle_hours,
       logon_time,
       sql_id
FROM   gv$session
WHERE  status = 'INACTIVE'
AND    type   = 'USER'
ORDER BY last_call_et DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="04_long_running_sessions.sql",
            category="06_Sessions_Processes",
            purpose="Active sessions with LAST_CALL_ET over a threshold",
            difficulty="Intermediate",
            production_use="YES",
            description="""Finds database calls that have been running longer than &min_seconds.
For EBS concurrent requests, also use folder 22 — this script is instance-level.""",
            queries=[
                Query(
                    title="Long-running active calls",
                    what="ACTIVE sessions with LAST_CALL_ET >= &min_seconds.",
                    columns="SID, SQL_ID, LAST_CALL_ET, EVENT, MODULE.",
                    interpret="LAST_CALL_ET is the current call duration, not the session age.",
                    problem="A session running 8 hours on a form SQL during business hours.",
                    action="Get SQL_ID, plan, waits (08_SQL_Tuning / 25_EBS troubleshooting).",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION, GV_$SQL",
                    sql="""DEFINE min_seconds = 600

SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       s.action,
       s.program,
       s.sql_id,
       s.event,
       s.last_call_et,
       ROUND(s.last_call_et/60,1) AS minutes_running,
       q.sql_text
FROM   gv$session s
LEFT JOIN gv$sql q
       ON q.inst_id = s.inst_id AND q.sql_id = s.sql_id AND q.child_number = s.sql_child_number
WHERE  s.status = 'ACTIVE'
AND    s.type   = 'USER'
AND    s.last_call_et >= &min_seconds
ORDER BY s.last_call_et DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="05_sessions_by_user.sql",
            category="06_Sessions_Processes",
            purpose="Session counts grouped by database username",
            difficulty="Basic",
            production_use="YES",
            description="""Finds which schema is opening too many connections (APPS, a batch
user, a misconfigured datasource).""",
            queries=[
                Query(
                    title="Counts by username and status",
                    what="Aggregates GV$SESSION by USERNAME, STATUS.",
                    columns="USERNAME, STATUS, SESSIONS.",
                    interpret="EBS: APPS will dominate. A sudden spike vs baseline is the signal.",
                    problem="A custom user with hundreds of sessions (connection leak).",
                    action="Check the middle-tier pool. Do not raise SESSIONS until the leak is understood.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       NVL(username, 'BACKGROUND') AS username,
       status,
       COUNT(*) AS sessions,
       COUNT(DISTINCT inst_id) AS instances
FROM   gv$session
GROUP BY username, status
ORDER BY sessions DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="06_sessions_by_machine.sql",
            category="06_Sessions_Processes",
            purpose="Session counts by client machine",
            difficulty="Basic",
            production_use="YES",
            description="""Identifies which app tier, concurrent tier, or PC is connected.
Useful when one apps node is misbehaving.""",
            queries=[
                Query(
                    title="Counts by machine",
                    what="Aggregates GV$SESSION by MACHINE.",
                    columns="MACHINE, SESSIONS, USERS.",
                    interpret="EBS app tiers should have a stable count. A desktop with 50 sessions is unusual.",
                    problem="One machine opening sessions until PROCESSES is exhausted.",
                    action="Check that host's connection pool / runaway script.",
                    caution="Safe. MACHINE can be shortened or show JDBC thin identifiers.",
                    privileges="SELECT on GV_$SESSION",
                    ebs="Useful for EBS",
                    sql="""SELECT
       machine,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions,
       COUNT(DISTINCT username) AS usernames
FROM   gv$session
WHERE  type = 'USER'
GROUP BY machine
ORDER BY sessions DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="07_sessions_by_program.sql",
            category="06_Sessions_Processes",
            purpose="Session counts by PROGRAM",
            difficulty="Basic",
            production_use="YES",
            description="""PROGRAM distinguishes Forms, JDBC, RMAN, sqlplus, and concurrent
managers (FNDLIBR, INVLIBR, etc.).""",
            queries=[
                Query(
                    title="Counts by program",
                    what="Aggregates GV$SESSION by PROGRAM.",
                    columns="PROGRAM, SESSIONS.",
                    interpret="FNDLIBR is Standard Manager. Many sqlplus sessions may be ad hoc or monitoring.",
                    problem="Unexpected PROGRAM flooding connections (backup agent, Excel ODBC).",
                    action="Trace the binary on the client host.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    ebs="Useful for EBS",
                    sql="""SELECT
       program,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions
FROM   gv$session
GROUP BY program
ORDER BY sessions DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="08_sessions_by_module.sql",
            category="06_Sessions_Processes",
            purpose="Session counts by MODULE / ACTION (EBS instrumentation)",
            difficulty="Intermediate",
            production_use="YES",
            description="""EBS sets MODULE to the form or concurrent program name via
DBMS_APPLICATION_INFO. This is the fastest way to map DB load to a
screen or concurrent program without joining FND tables.""",
            queries=[
                Query(
                    title="Counts by module",
                    what="Aggregates GV$SESSION by MODULE.",
                    columns="MODULE, ACTION, SESSIONS.",
                    interpret="Empty MODULE is uninstrumented SQL*Plus or a job that did not set it.",
                    problem="One MODULE with many ACTIVE sessions and a common SQL_ID.",
                    action="Tune that program or add a manager specialization.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    ebs="Critical for EBS",
                    sql="""SELECT
       NVL(module, '(no module)') AS module,
       NVL(action, '(no action)') AS action,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions
FROM   gv$session
WHERE  type = 'USER'
GROUP BY module, action
ORDER BY sessions DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="09_sessions_by_service.sql",
            category="06_Sessions_Processes",
            purpose="Session counts by SERVICE_NAME",
            difficulty="Intermediate",
            production_use="YES",
            description="""On RAC, services pin workloads (OLTP vs batch). Imbalance or
sessions on the wrong service after a failover is a configuration bug.""",
            queries=[
                Query(
                    title="Counts by service and instance",
                    what="Aggregates GV$SESSION by SERVICE_NAME, INST_ID.",
                    columns="SERVICE_NAME, INST_ID, SESSIONS.",
                    interpret="Compare to planned service cardinality (15_RAC/03).",
                    problem="All batch sessions landing on the OLTP node.",
                    action="Fix service configuration / TNS. See 15_RAC.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    notes="RAC where applicable. Useful on single instance too.",
                    sql="""SELECT
       service_name,
       inst_id,
       COUNT(*) AS sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) AS active_sessions
FROM   gv$session
GROUP BY service_name, inst_id
ORDER BY service_name, inst_id;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="10_sessions_by_sql_id.sql",
            category="06_Sessions_Processes",
            purpose="Which SQL_IDs are being executed right now",
            difficulty="Intermediate",
            production_use="YES",
            description="""Groups ACTIVE sessions by SQL_ID to find a stampeding query.""",
            queries=[
                Query(
                    title="Active sessions per SQL_ID",
                    what="Aggregates ACTIVE GV$SESSION by SQL_ID.",
                    columns="SQL_ID, SESSIONS, SAMPLE_TEXT.",
                    interpret="Many sessions / one SQL_ID = plan issue or missing bind peek / data skew.",
                    problem="A reporting SQL_ID with 40 sessions during peak.",
                    action="Take the SQL_ID to 08_SQL_Tuning.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION, GV_$SQL",
                    sql="""SELECT
       s.sql_id,
       COUNT(*) AS sessions,
       MIN(s.event) AS sample_event,
       MIN(SUBSTR(q.sql_text,1,120)) AS sql_text
FROM   gv$session s
LEFT JOIN gv$sql q
       ON q.inst_id = s.inst_id AND q.sql_id = s.sql_id AND q.child_number = s.sql_child_number
WHERE  s.status = 'ACTIVE'
AND    s.sql_id IS NOT NULL
GROUP BY s.sql_id
ORDER BY sessions DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="11_sessions_consuming_cpu.sql",
            category="06_Sessions_Processes",
            purpose="Sessions with highest recent CPU from V$SESSTAT / ASH",
            difficulty="Advanced",
            production_use="YES",
            description="""V$SESSTAT CPU used by this session is cumulative since login.
For 'who is on CPU right now' prefer ASH (licensed) or V$SESSION
in ON CPU / wait_class = Idle exclusion.""",
            extra_header="ASH queries require Diagnostics Pack. SESSTAT does not.",
            queries=[
                Query(
                    title="CPU from SESSTAT (cumulative) and on-CPU sessions",
                    what="Joins GV$SESSTAT (CPU used by this session) to sessions; lists sessions not waiting.",
                    columns="SID, CPU_CENTS, LAST_CALL_ET, EVENT.",
                    interpret="Cumulative CPU favors long-lived sessions. Pair with LAST_CALL_ET.",
                    problem="A session burning CPU with a bad plan (nested loops + high cardinality).",
                    action="Get SQL_ID and plan. Do not kill blindly — it may be a needed payroll job.",
                    caution="Safe. ASH optional query is commented with license note.",
                    privileges="SELECT on GV_$SESSTAT, GV_$STATNAME, GV_$SESSION",
                    sql="""SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       s.sql_id,
       s.event,
       s.last_call_et,
       ROUND(st.value/100,1) AS cpu_seconds
FROM   gv$session s
JOIN   gv$sesstat st ON st.inst_id = s.inst_id AND st.sid = s.sid
JOIN   gv$statname sn ON sn.inst_id = st.inst_id AND sn.statistic# = st.statistic#
WHERE  sn.name = 'CPU used by this session'
AND    s.type = 'USER'
AND    st.value > 0
ORDER BY st.value DESC
FETCH FIRST 30 ROWS ONLY;

-- Currently not waiting (likely on CPU or between waits)
SELECT inst_id, sid, serial#, username, sql_id, event, state, wait_class, last_call_et
FROM   gv$session
WHERE  status = 'ACTIVE'
AND    type = 'USER'
AND    wait_class = 'Idle' OR state = 'WAITED SHORT TIME' OR event = 'ON CPU'
ORDER BY last_call_et DESC;

-- LICENSING: Diagnostics Pack required for GV$ACTIVE_SESSION_HISTORY
-- SELECT inst_id, session_id, sql_id, COUNT(*) samples
-- FROM   gv$active_session_history
-- WHERE  sample_time > SYSDATE - 15/1440
-- AND    session_state = 'ON CPU'
-- GROUP BY inst_id, session_id, sql_id
-- ORDER BY samples DESC FETCH FIRST 20 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="12_sessions_consuming_pga.sql",
            category="06_Sessions_Processes",
            purpose="Top PGA consumers among current sessions",
            difficulty="Intermediate",
            production_use="YES",
            description="""Uses GV$PROCESS.PGA_USED_MEM / PGA_ALLOC_MEM joined to sessions.
Complements 11_Memory PGA scripts.""",
            queries=[
                Query(
                    title="Sessions by PGA",
                    what="Joins GV$SESSION to GV$PROCESS.",
                    columns="SID, PGA_USED_MB, PGA_ALLOC_MB, SQL_ID.",
                    interpret="PGA of several GB often means a large hash/sort that should have spilled or a leak (unclosed LOB/cursor).",
                    problem="One session near pga_aggregate_limit (ORA-04036) or triggering ORA-04030.",
                    action="Tune SQL workarea or raise pga_aggregate_target only after analysis. See 11_Memory.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION, GV_$PROCESS",
                    sql="""SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       s.sql_id,
       ROUND(p.pga_used_mem/1024/1024,1) AS pga_used_mb,
       ROUND(p.pga_alloc_mem/1024/1024,1) AS pga_alloc_mb,
       ROUND(p.pga_max_mem/1024/1024,1) AS pga_max_mb
FROM   gv$session s
JOIN   gv$process p ON p.inst_id = s.inst_id AND p.addr = s.paddr
WHERE  s.type = 'USER'
ORDER BY p.pga_alloc_mem DESC
FETCH FIRST 40 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="13_sessions_generating_io.sql",
            category="06_Sessions_Processes",
            purpose="Sessions with high physical reads/writes",
            difficulty="Advanced",
            production_use="YES",
            description="""Cumulative SESSTAT physical reads/writes. Good for finding a
session that has done a lot of I/O this life; not a rate. For rates
use AWR/ASH (licensed) or take two snapshots.""",
            queries=[
                Query(
                    title="Physical I/O by session (cumulative)",
                    what="Pivots key I/O statistics from GV$SESSTAT.",
                    columns="SID, PHY_READS, PHY_WRITES, SQL_ID.",
                    interpret="Long-lived APPS sessions accumulate I/O — sort by recent LAST_CALL_ET as well.",
                    problem="A session with huge physical reads and a full-table-scan plan.",
                    action="08_SQL_Tuning / 09 wait db file scattered read.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSTAT, GV_$STATNAME, GV_$SESSION",
                    sql="""SELECT
       s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.sql_id,
       s.last_call_et,
       MAX(CASE WHEN sn.name = 'physical reads' THEN st.value END) AS phy_reads,
       MAX(CASE WHEN sn.name = 'physical writes' THEN st.value END) AS phy_writes,
       MAX(CASE WHEN sn.name = 'physical read bytes' THEN ROUND(st.value/1024/1024) END) AS phy_read_mb
FROM   gv$session s
JOIN   gv$sesstat st ON st.inst_id = s.inst_id AND st.sid = s.sid
JOIN   gv$statname sn ON sn.inst_id = st.inst_id AND sn.statistic# = st.statistic#
WHERE  sn.name IN ('physical reads','physical writes','physical read bytes')
AND    s.type = 'USER'
GROUP BY s.inst_id, s.sid, s.serial#, s.username, s.sql_id, s.last_call_et
ORDER BY phy_reads DESC NULLS LAST
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="14_sessions_waiting.sql",
            category="06_Sessions_Processes",
            purpose="Active sessions currently waiting (non-idle)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Wait-class filtered view. Idle wait classes are excluded so you
see real stalls.""",
            queries=[
                Query(
                    title="Non-idle waiters",
                    what="GV$SESSION where WAIT_CLASS <> Idle and STATUS ACTIVE.",
                    columns="EVENT, WAIT_CLASS, SECONDS_IN_WAIT, SQL_ID, BLOCKING_SESSION.",
                    interpret="WAIT_CLASS Concurrency / Application / Commit / User I/O drive the next script you open.",
                    problem="Many waiters, one BLOCKING_SESSION.",
                    action="10_Locks_Blocking if Application/Concurrency; 09_Wait_Events otherwise.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       inst_id,
       sid,
       serial#,
       username,
       module,
       sql_id,
       event,
       wait_class,
       state,
       seconds_in_wait,
       blocking_session,
       blocking_instance,
       p1text, p1, p2text, p2, p3text, p3
FROM   gv$session
WHERE  status = 'ACTIVE'
AND    wait_class <> 'Idle'
ORDER BY wait_class, event, seconds_in_wait DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="15_sessions_waiting_on_locks.sql",
            category="06_Sessions_Processes",
            purpose="Sessions waiting on enqueue / TX / TM locks",
            difficulty="Intermediate",
            production_use="YES",
            description="""Quick filter for lock waits. Full chain analysis is folder 10.""",
            queries=[
                Query(
                    title="Enqueue waiters",
                    what="Filters events like enq:% or waiting on a blocking_session.",
                    columns="SID, EVENT, BLOCKING_SESSION, SQL_ID.",
                    interpret="enq: TX - row lock contention is a row lock. enq: TM is usually unindexed FK or table lock.",
                    problem="A tree of waiters behind one inactive Forms session.",
                    action="Open 10_Locks_Blocking/01 and /11.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       inst_id,
       sid,
       serial#,
       username,
       module,
       sql_id,
       event,
       seconds_in_wait,
       blocking_session,
       blocking_instance,
       blocking_session_status
FROM   gv$session
WHERE  blocking_session IS NOT NULL
OR     event LIKE 'enq:%'
OR     event LIKE 'cursor: pin%'
ORDER BY blocking_instance, blocking_session, seconds_in_wait DESC;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="16_generate_kill_session.sql",
            category="06_Sessions_Processes",
            purpose="Generate ALTER SYSTEM KILL SESSION commands (does not execute them)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Produces kill statements for review. KILL SESSION is destructive:
open transactions roll back, Forms users lose work, RAC needs
@inst_id syntax.""",
            extra_header="WARNING: Never run generated KILL commands without identifying the session and obtaining approval.",
            queries=[
                Query(
                    title="Generate kill commands for a filtered set",
                    what="Builds ALTER SYSTEM KILL SESSION 'sid,serial#,@inst' IMMEDIATE.",
                    columns="KILL_CMD, SID, USERNAME, MODULE, LAST_CALL_ET.",
                    interpret="Review each row. Adjust the WHERE clause before generating.",
                    problem="N/A — this is a helper, not a health check.",
                    action="Copy one command at a time after confirmation.",
                    caution="WARNING: Destructive. Generated only. IMMEDIATE forces rollback. On RAC include @inst_id.",
                    privileges="SELECT on GV_$SESSION. ALTER SYSTEM is required only to execute the generated command.",
                    sql="""-- Example filter: inactive APPS sessions idle > 8 hours. EDIT before use.
SELECT
       'ALTER SYSTEM KILL SESSION ''' || sid || ',' || serial# || ',@' || inst_id || ''' IMMEDIATE;' AS kill_cmd,
       inst_id,
       sid,
       serial#,
       username,
       machine,
       module,
       status,
       last_call_et
FROM   gv$session
WHERE  1 = 0  -- safety: returns no rows until you edit the predicate
-- AND username = 'APPS'
-- AND status = 'INACTIVE'
-- AND last_call_et > 28800
;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="17_generate_disconnect_session.sql",
            category="06_Sessions_Processes",
            purpose="Generate ALTER SYSTEM DISCONNECT SESSION ... POST_TRANSACTION commands",
            difficulty="Intermediate",
            production_use="YES",
            description="""DISCONNECT SESSION POST_TRANSACTION is gentler than KILL: it lets
the current transaction finish then drops the session. Use for inactive
Forms sessions holding locks when you can wait for a commit.""",
            extra_header="WARNING: Generated only. IMMEDIATE is more aggressive than POST_TRANSACTION.",
            queries=[
                Query(
                    title="Generate disconnect commands",
                    what="Builds DISCONNECT SESSION commands.",
                    columns="DISCONNECT_CMD, SID, STATUS.",
                    interpret="POST_TRANSACTION waits for commit/rollback. IMMEDIATE is similar to kill.",
                    problem="N/A — helper.",
                    action="Prefer POST_TRANSACTION for inactive lock holders if the user might commit.",
                    caution="WARNING: Destructive. Generated only. Safety predicate 1=0.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       'ALTER SYSTEM DISCONNECT SESSION ''' || sid || ',' || serial# || ',@' || inst_id || ''' POST_TRANSACTION;' AS disconnect_cmd,
       inst_id,
       sid,
       serial#,
       username,
       module,
       status,
       last_call_et
FROM   gv$session
WHERE  1 = 0  -- safety: edit before use
;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="18_process_usage.sql",
            category="06_Sessions_Processes",
            purpose="OS process list as seen by Oracle (V$PROCESS)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Maps SID to SPID for OS-level investigation (pstack, top).""",
            queries=[
                Query(
                    title="Process to session map",
                    what="Joins GV$PROCESS to GV$SESSION.",
                    columns="SPID, SID, PROGRAM, PGA_ALLOC_MB.",
                    interpret="SPID is the OS pid on that instance's host.",
                    problem="Orphan processes (process without session) after a kill -9 — rare; more often extra parallel slaves.",
                    action="Use SPID on the correct RAC node. Do not kill -9 Oracle processes.",
                    caution="Safe to query. Never kill -9 smon/pmon/lmd.",
                    privileges="SELECT on GV_$PROCESS, GV_$SESSION",
                    sql="""SELECT
       p.inst_id,
       p.spid,
       p.pid,
       s.sid,
       s.serial#,
       s.username,
       s.program,
       p.program AS process_program,
       ROUND(p.pga_alloc_mem/1024/1024,1) AS pga_alloc_mb
FROM   gv$process p
LEFT JOIN gv$session s ON s.inst_id = p.inst_id AND s.paddr = p.addr
ORDER BY p.inst_id, p.spid;""",
                )
            ],
        ),
        Script(
            folder="06_Sessions_Processes",
            file_name="19_session_process_utilization.sql",
            category="06_Sessions_Processes",
            purpose="Utilization of processes/sessions parameters with headroom alerts",
            difficulty="Intermediate",
            production_use="YES",
            description="""Combines V$RESOURCE_LIMIT with current session counts. Use during
connection storms and before raising processes.""",
            queries=[
                Query(
                    title="Utilization vs limits",
                    what="V$RESOURCE_LIMIT plus per-instance session counts.",
                    columns="CURRENT_UTILIZATION, LIMIT_VALUE, ALERT_LEVEL.",
                    interpret=">85% WARNING, >95% CRITICAL.",
                    problem="CURRENT ≈ LIMIT — next connection gets ORA-00020 / ORA-00018.",
                    action="Find leaks first (by machine/program). Raising processes requires a bounce on 19c.",
                    caution="Safe.",
                    privileges="SELECT on V_$RESOURCE_LIMIT, GV_$SESSION",
                    sql="""SELECT
       resource_name,
       current_utilization,
       max_utilization,
       limit_value,
       CASE
         WHEN REGEXP_LIKE(limit_value,'^[0-9]+$')
          AND current_utilization*100/TO_NUMBER(limit_value) > 95 THEN 'CRITICAL'
         WHEN REGEXP_LIKE(limit_value,'^[0-9]+$')
          AND current_utilization*100/TO_NUMBER(limit_value) > 85 THEN 'WARNING'
         WHEN REGEXP_LIKE(limit_value,'^[0-9]+$')
          AND current_utilization*100/TO_NUMBER(limit_value) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   v$resource_limit
WHERE  resource_name IN ('processes','sessions');

SELECT inst_id, COUNT(*) sessions,
       SUM(DECODE(type,'USER',1,0)) user_sessions,
       SUM(DECODE(type,'BACKGROUND',1,0)) bg_sessions
FROM   gv$session
GROUP BY inst_id
ORDER BY inst_id;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
