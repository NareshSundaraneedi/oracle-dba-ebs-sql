#!/usr/bin/env python3
from _writer import Query, Script, write_many


INTRO = """How to identify lock roles:
  BLOCKER           = session that holds the enqueue and is not waiting on a lock (or is the root)
  BLOCKED SESSION   = session with BLOCKING_SESSION set or waiting on enq:
  WAIT EVENT        = typically enq: TX - row lock contention or enq: TM - contention
  OBJECT            = DBA_OBJECTS via current SQL or V$LOCKED_OBJECT
  SQL_ID            = waiter and blocker current/prev SQL
  MACHINE/PROGRAM/MODULE/USERNAME = from GV$SESSION
"""


def scripts():
    return [
        Script(
            folder="10_Locks_Blocking",
            file_name="01_blocking_sessions.sql",
            category="10_Locks_Blocking",
            purpose="List sessions that are blocking others right now",
            difficulty="Intermediate",
            production_use="YES",
            extra_header=INTRO,
            description="""First script to run on a locking incident. Shows the blocker
identity so you can call the user or decide on a disconnect.""",
            queries=[
                Query(
                    title="Current blockers",
                    what="Finds sessions whose SID is referenced as BLOCKING_SESSION.",
                    columns="BLOCKER SID/SERIAL/INST, USERNAME, MODULE, STATUS, SQL_ID, MACHINE, PROGRAM, EVENT.",
                    interpret="INACTIVE blocker + ACTIVE waiters = forgotten Forms session (classic EBS).",
                    problem="A blocker idle for hours with many waiters.",
                    action="Contact the user. Generate disconnect (06/17) if policy allows. Do not kill blindly if it is a payroll post.",
                    caution="Safe to query. Killing is destructive — not executed.",
                    privileges="SELECT on GV_$SESSION",
                    ebs="Critical for EBS",
                    sql="""SELECT DISTINCT
       b.inst_id              AS blocker_inst,
       b.sid                  AS blocker_sid,
       b.serial#              AS blocker_serial,
       b.username             AS blocker_user,
       b.status               AS blocker_status,
       b.event                AS blocker_event,
       b.sql_id               AS blocker_sql_id,
       b.prev_sql_id          AS blocker_prev_sql,
       b.module               AS blocker_module,
       b.program              AS blocker_program,
       b.machine              AS blocker_machine,
       b.osuser               AS blocker_osuser,
       b.last_call_et         AS blocker_last_call_et,
       COUNT(*) OVER (PARTITION BY b.inst_id, b.sid) AS waiter_count
FROM   gv$session w
JOIN   gv$session b
       ON b.inst_id = NVL(w.blocking_instance, w.inst_id)
      AND b.sid     = w.blocking_session
WHERE  w.blocking_session IS NOT NULL
ORDER BY waiter_count DESC, b.inst_id, b.sid;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="02_blocked_sessions.sql",
            category="10_Locks_Blocking",
            purpose="List sessions waiting on a blocker",
            difficulty="Intermediate",
            production_use="YES",
            extra_header=INTRO,
            description="""Waiter side: who is stuck, for how long, on which event and SQL.""",
            queries=[
                Query(
                    title="Current waiters",
                    what="Sessions with BLOCKING_SESSION IS NOT NULL.",
                    columns="WAITER SID, EVENT, SECONDS_IN_WAIT, SQL_ID, MODULE, BLOCKER.",
                    interpret="SECONDS_IN_WAIT of thousands = business impact. Same SQL_ID on many waiters = one hot row/table.",
                    problem="Order management waiters behind a single APPS form.",
                    action="Map MODULE to the form. Use 07_locked_objects for the object.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       w.inst_id,
       w.sid            AS blocked_sid,
       w.serial#        AS blocked_serial,
       w.username,
       w.module,
       w.program,
       w.machine,
       w.sql_id,
       w.event          AS wait_event,
       w.seconds_in_wait,
       w.blocking_instance,
       w.blocking_session,
       w.blocking_session_status
FROM   gv$session w
WHERE  w.blocking_session IS NOT NULL
ORDER BY w.seconds_in_wait DESC;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="03_blocking_chains.sql",
            category="10_Locks_Blocking",
            purpose="Assemble blocker→waiter chains including multi-level",
            difficulty="Advanced",
            production_use="YES",
            extra_header=INTRO + "Difference vs 11_blocking_tree.sql: this is a flat pair list plus a CONNECT BY tree in one file; 11 is a formatted tree only.",
            description="""Shows A blocks B blocks C. You must treat the root, not the middle.""",
            queries=[
                Query(
                    title="Lock chains",
                    what="Hierarchical query on GV$SESSION blocking columns.",
                    columns="CHAIN, LEVEL, ROOT_BLOCKER, WAIT_EVENT.",
                    interpret="LEVEL 1 is the root blocker. Highest LEVEL is the tail waiter.",
                    problem="A long chain — killing a middle session just shifts the wait.",
                    action="Act on the root blocker only.",
                    caution="Safe. CONNECT BY can be messy with RAC; uses inst:sid keys.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       LPAD(' ', 2*(LEVEL-1)) || inst_id || ':' || sid || ' ' || username || ' ' || status AS chain,
       LEVEL,
       CONNECT_BY_ISLEAF AS is_leaf,
       event AS wait_event,
       sql_id,
       module,
       machine,
       program,
       seconds_in_wait
FROM   gv$session
WHERE  blocking_session IS NOT NULL
OR     (inst_id, sid) IN (
         SELECT NVL(blocking_instance, inst_id), blocking_session
         FROM   gv$session
         WHERE  blocking_session IS NOT NULL
       )
START WITH blocking_session IS NULL
AND (inst_id, sid) IN (
         SELECT NVL(blocking_instance, inst_id), blocking_session
         FROM   gv$session
         WHERE  blocking_session IS NOT NULL
       )
CONNECT BY blocking_session = PRIOR sid
AND        NVL(blocking_instance, inst_id) = PRIOR inst_id;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="04_row_locks.sql",
            category="10_Locks_Blocking",
            purpose="Row-level TX lock waiters (enq: TX - row lock contention)",
            difficulty="Advanced",
            production_use="YES",
            extra_header=INTRO + """TX row lock: waiter wants a row held by an uncommitted DML.
P1/P2/P3 decode: usn/slot/seq of the undo for the holder (advanced).""",
            description="""Filters to the classic row-lock event. Use when the wait event
is specifically row lock contention, not TM.""",
            queries=[
                Query(
                    title="TX row lock waiters and holders",
                    what="Filters EVENT = enq: TX - row lock contention and maps blockers.",
                    columns="WAITER, BLOCKER, SQL_ID, MODULE, SECONDS.",
                    interpret="Same table/row usually means two forms on the same document.",
                    problem="Many waiters, one blocker on a setup table (single-row bottleneck).",
                    action="User communication. Application design for hot rows.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       w.inst_id, w.sid waiter_sid, w.serial#, w.username waiter_user,
       w.module, w.sql_id waiter_sql, w.seconds_in_wait,
       w.event,
       b.inst_id blocker_inst, b.sid blocker_sid, b.serial# blocker_serial,
       b.username blocker_user, b.status blocker_status,
       b.module blocker_module, b.sql_id blocker_sql, b.prev_sql_id,
       b.machine, b.program
FROM   gv$session w
JOIN   gv$session b
       ON b.sid = w.blocking_session
      AND b.inst_id = NVL(w.blocking_instance, w.inst_id)
WHERE  w.event = 'enq: TX - row lock contention'
ORDER BY w.seconds_in_wait DESC;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="05_tx_locks.sql",
            category="10_Locks_Blocking",
            purpose="All TX enqueue modes (row lock, ITL, index contention)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="""enq: TX has several modes:
  row lock contention     = uncommitted row
  allocate ITL entry      = INITRANS / ITL shortage
  index contention        = index block split / unique key
Difference vs 04: 04 is row lock only; this file includes ITL and index TX.""",
            description="""Do not treat every TX wait as a missing COMMIT.""",
            queries=[
                Query(
                    title="All TX enqueue waits",
                    what="EVENT LIKE enq: TX%.",
                    columns="EVENT, SID, BLOCKER, SQL_ID.",
                    interpret="allocate ITL entry → consider INITRANS/ASSM (often not the first knob). index contention → hot unique index.",
                    problem="ITL waits on a table after a massive parallel insert.",
                    action="Different fix than row locks — do not kill the blocker first; check the exact event text.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION, GV_$LOCK",
                    sql="""SELECT inst_id, sid, serial#, username, event, seconds_in_wait,
       blocking_session, blocking_instance, sql_id, module
FROM   gv$session
WHERE  event LIKE 'enq: TX%'
ORDER BY event, seconds_in_wait DESC;

SELECT inst_id, sid, type, lmode, request, id1, id2, block, ctime
FROM   gv$lock
WHERE  type = 'TX'
ORDER BY block DESC, ctime DESC;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="06_tm_locks.sql",
            category="10_Locks_Blocking",
            purpose="TM (table) locks — often unindexed FK or explicit LOCK TABLE",
            difficulty="Advanced",
            production_use="YES",
            extra_header="""enq: TM - contention: waiting for a table lock.
Common EBS cause: DELETE/UPDATE parent while child FK is unindexed.
See 05_Objects/07_foreign_keys.sql.""",
            description="""TM locks block DDL and can queue DML. Identify the object via
ID1 (object_id) on the TM lock.""",
            queries=[
                Query(
                    title="TM locks and objects",
                    what="Joins GV$LOCK TYPE=TM to DBA_OBJECTS.",
                    columns="OBJECT_NAME, LMODE, REQUEST, SID, EVENT.",
                    interpret="LMODE 3 = row-X (SX) typical DML. REQUEST 5+ is someone wanting a higher table lock (DDL or LOCK TABLE).",
                    problem="A CTAS/DDL waiting behind DML, or parent delete causing TM on child.",
                    action="Find unindexed FK. Reschedule DDL.",
                    caution="Safe.",
                    privileges="SELECT on GV_$LOCK, GV_$SESSION, DBA_OBJECTS",
                    ebs="Useful for EBS",
                    sql="""SELECT
       l.inst_id,
       l.sid,
       s.serial#,
       s.username,
       s.event,
       s.sql_id,
       s.module,
       l.lmode,
       l.request,
       l.ctime,
       o.owner,
       o.object_name,
       o.object_type
FROM   gv$lock l
JOIN   gv$session s ON s.inst_id = l.inst_id AND s.sid = l.sid
LEFT JOIN dba_objects o ON o.object_id = l.id1
WHERE  l.type = 'TM'
ORDER BY l.request DESC, l.ctime DESC;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="07_locked_objects.sql",
            category="10_Locks_Blocking",
            purpose="Objects currently locked (V$LOCKED_OBJECT)",
            difficulty="Intermediate",
            production_use="YES",
            extra_header=INTRO,
            description="""Maps sessions to locked objects. Essential for telling the
functional team 'which document/table'.""",
            queries=[
                Query(
                    title="Locked objects with session identity",
                    what="Joins V$LOCKED_OBJECT to sessions and DBA_OBJECTS.",
                    columns="OWNER, OBJECT_NAME, LOCKED_MODE, USERNAME, MODULE, MACHINE, SQL_ID.",
                    interpret="LOCKED_MODE 3 = row exclusive (DML). Mode 6 = exclusive.",
                    problem="A setup table locked exclusively.",
                    action="Identify the blocker via 01 using the SESSION_ID.",
                    caution="Safe. RAC: use GV$LOCKED_OBJECT.",
                    privileges="SELECT on GV_$LOCKED_OBJECT, GV_$SESSION, DBA_OBJECTS",
                    sql="""SELECT
       lo.inst_id,
       lo.session_id,
       s.serial#,
       s.username,
       s.status,
       s.module,
       s.program,
       s.machine,
       s.sql_id,
       s.event,
       lo.locked_mode,
       o.owner,
       o.object_name,
       o.object_type,
       lo.os_user_name
FROM   gv$locked_object lo
JOIN   dba_objects o ON o.object_id = lo.object_id
JOIN   gv$session s ON s.inst_id = lo.inst_id AND s.sid = lo.session_id
ORDER BY o.owner, o.object_name, lo.inst_id, lo.session_id;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="08_sessions_waiting_for_locks.sql",
            category="10_Locks_Blocking",
            purpose="Waiters only, with object and blocker SQL",
            difficulty="Intermediate",
            production_use="YES",
            extra_header=INTRO,
            description="""Convenience join of waiters to locked objects for a single output
used on bridges.""",
            queries=[
                Query(
                    title="Waiters with object names",
                    what="Waiters plus objects locked by their blocker.",
                    columns="BLOCKED SESSION, WAIT EVENT, OBJECT, BLOCKER, SQL_IDs.",
                    interpret="Object list on the blocker may include more than the contended row's table.",
                    problem="Waiters on a critical EBS table (OE_ORDER_HEADERS_ALL, GL_JE_LINES).",
                    action="Functional escalation with object name + blocker module.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION, GV_$LOCKED_OBJECT, DBA_OBJECTS",
                    sql="""SELECT
       w.inst_id waiter_inst,
       w.sid waiter_sid,
       w.username waiter_user,
       w.event wait_event,
       w.sql_id waiter_sql,
       w.module waiter_module,
       w.seconds_in_wait,
       b.sid blocker_sid,
       b.username blocker_user,
       b.status blocker_status,
       b.module blocker_module,
       b.sql_id blocker_sql,
       b.machine blocker_machine,
       b.program blocker_program,
       o.owner,
       o.object_name
FROM   gv$session w
JOIN   gv$session b
       ON b.sid = w.blocking_session
      AND b.inst_id = NVL(w.blocking_instance, w.inst_id)
LEFT JOIN gv$locked_object lo
       ON lo.inst_id = b.inst_id AND lo.session_id = b.sid
LEFT JOIN dba_objects o ON o.object_id = lo.object_id
WHERE  w.blocking_session IS NOT NULL
ORDER BY w.seconds_in_wait DESC;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="09_lock_duration.sql",
            category="10_Locks_Blocking",
            purpose="How long locks have been held (V$LOCK.CTIME)",
            difficulty="Intermediate",
            production_use="YES",
            description="""CTIME is seconds since the lock was taken. Long CTIME on a
TX lock is an uncommitted transaction.""",
            queries=[
                Query(
                    title="Long-held locks",
                    what="GV$LOCK ordered by CTIME for TX/TM.",
                    columns="SID, TYPE, LMODE, CTIME, USERNAME.",
                    interpret="CTIME 20000s = ~5.5 hours uncommitted.",
                    problem="Long TX during high concurrency.",
                    action="Find the session (STATUS, MODULE). Ask for commit/rollback or disconnect POST_TRANSACTION.",
                    caution="Safe.",
                    privileges="SELECT on GV_$LOCK, GV_$SESSION",
                    sql="""SELECT
       l.inst_id,
       l.sid,
       s.serial#,
       s.username,
       s.status,
       s.module,
       s.machine,
       l.type,
       l.lmode,
       l.request,
       l.ctime AS seconds_held,
       ROUND(l.ctime/60,1) AS minutes_held,
       s.sql_id
FROM   gv$lock l
JOIN   gv$session s ON s.inst_id = l.inst_id AND s.sid = l.sid
WHERE  l.type IN ('TX','TM','UL')
AND    l.lmode > 0
ORDER BY l.ctime DESC
FETCH FIRST 50 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="10_deadlock_investigation.sql",
            category="10_Locks_Blocking",
            purpose="Investigate ORA-00060 deadlocks after they occur",
            difficulty="Advanced",
            production_use="YES",
            extra_header="""Deadlocks are resolved by Oracle (one session rolls back).
This script does not 'find a live deadlock' — they last milliseconds.
Use the alert log / trace file. See also 30_Advanced/06_ora_00060.""",
            description="""Points you at the trace. Optionally searches recent ASH for
enqueue waits if licensed.""",
            queries=[
                Query(
                    title="Alert log location and recent enqueue ASH (optional)",
                    what="Prints Diag Trace path; optional ASH enqueue samples.",
                    columns="VALUE path, ASH samples.",
                    interpret="Open the ORA-00060 trace — it contains the two SQLs and objects.",
                    problem="Repeated deadlocks on the same tables = application locking order bug.",
                    action="Give the trace to development. Do not increase INITRANS to 'fix' deadlocks.",
                    caution="ASH portion needs Diagnostics Pack — commented.",
                    privileges="SELECT on V_$DIAG_INFO",
                    sql="""SELECT name, value FROM v$diag_info
WHERE  name IN ('Diag Trace','Default Trace File','ADR Home');

PROMPT Search the alert log for ORA-00060 and open the referenced trace file.
PROMPT The trace lists Deadlock graph, rows, and SQL.

-- Diagnostics Pack optional:
-- SELECT sample_time, session_id, sql_id, event, blocking_session
-- FROM   gv$active_session_history
-- WHERE  sample_time > SYSDATE - 1
-- AND    event LIKE 'enq:%'
-- ORDER BY sample_time DESC FETCH FIRST 50 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="11_blocking_tree.sql",
            category="10_Locks_Blocking",
            purpose="Formatted blocking tree for incident bridges",
            difficulty="Advanced",
            production_use="YES",
            extra_header=INTRO,
            description="""Single output designed to paste into a ticket. Difference vs
03: presentation-focused with blocker/blocked labels.""",
            queries=[
                Query(
                    title="Pretty blocking tree",
                    what="Hierarchical formatted output.",
                    columns="TREE, ROLE, WAIT_EVENT, OBJECT hint via module/sql.",
                    interpret="Root line is BLOCKER. Indented lines are BLOCKED SESSION.",
                    problem="Any tree during business hours on order/finance modules.",
                    action="Escalate with this output plus 07 objects.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SESSION",
                    sql="""SELECT
       LPAD('+- ', 3*(LEVEL-1), ' ') ||
       CASE WHEN LEVEL = 1 THEN 'BLOCKER ' ELSE 'BLOCKED ' END ||
       username || ' inst=' || inst_id || ' sid=' || sid || ',' || serial# ||
       ' status=' || status ||
       ' event=' || event ||
       ' sql=' || NVL(sql_id,'-') ||
       ' module=' || NVL(module,'-') ||
       ' machine=' || NVL(machine,'-') ||
       ' program=' || NVL(program,'-') AS tree
FROM   gv$session
START WITH blocking_session IS NULL
AND (inst_id, sid) IN (
       SELECT NVL(blocking_instance, inst_id), blocking_session
       FROM   gv$session WHERE blocking_session IS NOT NULL)
CONNECT BY PRIOR sid = blocking_session
AND PRIOR inst_id = NVL(blocking_instance, inst_id);""",
                )
            ],
        ),
        Script(
            folder="10_Locks_Blocking",
            file_name="12_rac_blocking_sessions.sql",
            category="10_Locks_Blocking",
            purpose="Cross-instance blocking on RAC (including global locks)",
            difficulty="Advanced",
            production_use="YES",
            extra_header="RAC where applicable. BLOCKING_INSTANCE is required — never assume the blocker is local.",
            description="""On RAC a waiter on node 2 may be blocked by node 1. Also check
gv$ges_blocking_enqueue for global enqueue details.""",
            queries=[
                Query(
                    title="RAC cross-instance blockers",
                    what="Highlights blocking_instance <> waiter inst_id and GES view if available.",
                    columns="WAITER_INST, BLOCKER_INST, EVENT, SID.",
                    interpret="Cross-instance TX is still a row lock; just the holder is remote.",
                    problem="All waiters on node 2, blocker on node 1 — still kill/disconnect the root on node 1.",
                    action="Use KILL SESSION 'sid,serial#,@inst'.",
                    caution="Safe. gv$ges_blocking_enqueue may be empty if no global enqueue wait.",
                    privileges="SELECT on GV_$SESSION, GV_$GES_BLOCKING_ENQUEUE",
                    notes="RAC where applicable.",
                    sql="""SELECT
       w.inst_id waiter_inst,
       w.sid waiter_sid,
       w.event,
       w.sql_id,
       w.seconds_in_wait,
       w.blocking_instance,
       w.blocking_session,
       b.username blocker_user,
       b.status blocker_status,
       b.module blocker_module,
       b.machine
FROM   gv$session w
JOIN   gv$session b
       ON b.inst_id = w.blocking_instance
      AND b.sid     = w.blocking_session
WHERE  w.blocking_session IS NOT NULL
ORDER BY CASE WHEN w.inst_id <> w.blocking_instance THEN 0 ELSE 1 END,
         w.seconds_in_wait DESC;

SELECT * FROM gv$ges_blocking_enqueue;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
