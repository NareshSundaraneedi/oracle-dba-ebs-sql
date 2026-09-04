#!/usr/bin/env python3
from _writer import Query, Script, write_many


def wait_script(file_name, purpose, difficulty, description, extra, queries):
    return Script(
        folder="09_Wait_Events",
        file_name=file_name,
        category="09_Wait_Events",
        purpose=purpose,
        difficulty=difficulty,
        production_use="YES",
        extra_header=extra,
        description=description,
        queries=queries,
    )


GUIDE = """Meaning → Possible Cause → How to Investigate → Possible Fix is documented per query."""


def scripts():
    return [
        wait_script(
            "01_system_wait_events.sql",
            "Instance-level wait event totals since startup (non-idle)",
            "Intermediate",
            """GV$SYSTEM_EVENT since-startup totals. Good for a first look; not a
rate. For a time window use 08_SQL_Tuning/18 (AWR, licensed).
""" + GUIDE,
            "Pack-free. Difference vs 03_top_wait_events.sql: this is the full list; 03 is ranked top-N with average wait.",
            [
                Query(
                    title="Non-idle system events",
                    what="Reads GV$SYSTEM_EVENT excluding Idle.",
                    columns="EVENT, TOTAL_WAITS, TIME_WAITED_S, AVG_MS, WAIT_CLASS.",
                    interpret="TIME_WAITED is cumulative. Compare AVG_MS to your storage/commit SLOs.",
                    problem="An event with huge TIME_WAITED that is not normally in the top 5.",
                    action="Open the event-specific script in this folder.",
                    caution="Safe. Since-startup bias toward events present since bounce.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    sql="""SELECT
       inst_id,
       event,
       wait_class,
       total_waits,
       total_timeouts,
       ROUND(time_waited_micro/1e6,1) AS time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) AS avg_wait_ms
FROM   gv$system_event
WHERE  wait_class <> 'Idle'
ORDER BY time_waited_micro DESC;""",
                )
            ],
        ),
        wait_script(
            "02_session_wait_events.sql",
            "Per-session wait totals (V$SESSION_EVENT)",
            "Intermediate",
            """Cumulative waits per session lifetime. Useful for a long-running
session; not for 'now' (use V$SESSION / ASH).""",
            "Pack-free.",
            [
                Query(
                    title="Session events for one SID or top waiters",
                    what="Reads GV$SESSION_EVENT joined to sessions.",
                    columns="SID, EVENT, TIME_WAITED_S.",
                    interpret="A session that lived for days accumulates everything — filter by current SQL.",
                    problem="One session with hours on enq: TX.",
                    action="10_Locks_Blocking.",
                    caution="Safe. Specify SID when possible.",
                    privileges="SELECT on GV_$SESSION_EVENT, GV_$SESSION",
                    sql="""DEFINE sid_p = 0

SELECT
       e.inst_id,
       e.sid,
       s.username,
       s.sql_id,
       e.event,
       e.wait_class,
       e.total_waits,
       ROUND(e.time_waited_micro/1e6,1) AS time_waited_s
FROM   gv$session_event e
JOIN   gv$session s ON s.inst_id = e.inst_id AND s.sid = e.sid
WHERE  e.wait_class <> 'Idle'
AND    ( &sid_p = 0 OR e.sid = &sid_p )
ORDER BY e.time_waited_micro DESC
FETCH FIRST 50 ROWS ONLY;""",
                )
            ],
        ),
        wait_script(
            "03_top_wait_events.sql",
            "Top 20 non-idle wait events with average wait",
            "Basic",
            """Daily/incident ranked wait view.""",
            "Pack-free.",
            [
                Query(
                    title="Top waits",
                    what="Top 20 from GV$SYSTEM_EVENT.",
                    columns="EVENT, TIME_WAITED_S, AVG_MS.",
                    interpret="High TIME with low AVG = many short waits (chatty). High AVG = latency.",
                    problem="avg_wait_ms for log file sync > 10ms on decent storage, or gc waits dominating a well-sized RAC.",
                    action="Event-specific file.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    sql="""SELECT
       inst_id,
       event,
       wait_class,
       total_waits,
       ROUND(time_waited_micro/1e6,1) AS time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) AS avg_wait_ms
FROM   gv$system_event
WHERE  wait_class <> 'Idle'
ORDER BY time_waited_micro DESC
FETCH FIRST 20 ROWS ONLY;""",
                )
            ],
        ),
        wait_script(
            "04_cpu_vs_wait.sql",
            "CPU vs wait breakdown from the time model",
            "Intermediate",
            """Answers: is the instance CPU-bound or wait-bound?
Meaning: DB CPU is Oracle CPU. DB time - DB CPU ≈ wait (+ unaccounted).
Cause: CPU-bound = plans/host saturation. Wait-bound = I/O, locks, commit, cluster.
Investigate: this script + AAS. Fix: tune the dominant component, do not add CPU to a lock problem.""",
            "Pack-free (V$SYS_TIME_MODEL).",
            [
                Query(
                    title="DB CPU vs DB time",
                    what="Computes CPU fraction of DB time.",
                    columns="DB_TIME_S, DB_CPU_S, CPU_PCT, WAIT_PCT.",
                    interpret="CPU_PCT > 80% CPU-bound. < 40% wait-bound.",
                    problem="CPU_PCT high and OS run queue > CPU_COUNT.",
                    action="Top SQL by CPU. If wait-bound, 03_top_wait_events.",
                    caution="Safe. Since startup.",
                    privileges="SELECT on GV_$SYS_TIME_MODEL",
                    sql="""SELECT
       inst_id,
       ROUND(db_time/1e6,1) AS db_time_s,
       ROUND(db_cpu/1e6,1) AS db_cpu_s,
       ROUND(db_cpu*100/NULLIF(db_time,0),1) AS cpu_pct_of_dbtime,
       ROUND((db_time-db_cpu)*100/NULLIF(db_time,0),1) AS wait_or_other_pct
FROM   (
       SELECT inst_id,
              MAX(CASE WHEN stat_name='DB time' THEN value END) db_time,
              MAX(CASE WHEN stat_name='DB CPU' THEN value END) db_cpu
       FROM   gv$sys_time_model
       GROUP BY inst_id
);""",
                )
            ],
        ),
        wait_script(
            "05_io_waits.sql",
            "All User I/O and System I/O wait events",
            "Intermediate",
            """Meaning: I/O wait class is time spent in storage calls.
Cause: slow disks, huge FTS, checkpoint writes, temp spills.
Investigate: avg wait ms, ASH by event, SQL with disk_reads.
Fix: tune SQL, add IOPs, separate redo/data — not 'increase SGA' as the first step.""",
            "Pack-free.",
            [
                Query(
                    title="I/O wait classes",
                    what="Filters WAIT_CLASS IN (User I/O, System I/O).",
                    columns="EVENT, TIME_WAITED_S, AVG_MS.",
                    interpret="User I/O is foreground. System I/O is DBWR/LGWR/ARCn.",
                    problem="User I/O avg > 10-20ms on SAN claimed to be flash.",
                    action="Storage team + top physical SQL.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    sql="""SELECT inst_id, wait_class, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class IN ('User I/O','System I/O')
ORDER BY time_waited_micro DESC;""",
                )
            ],
        ),
        wait_script(
            "06_user_io.sql",
            "Foreground User I/O only",
            "Intermediate",
            """Difference vs 05: excludes DBWR/LGWR System I/O so you see
application read/write waits only.""",
            "Pack-free.",
            [
                Query(
                    title="User I/O events",
                    what="WAIT_CLASS = User I/O.",
                    columns="EVENT, AVG_MS, TIME_S.",
                    interpret="sequential read = index/single-block. scattered read = multiblock FTS.",
                    problem="scattered read dominates OLTP hours.",
                    action="24_full_table_scans and 15/16 event scripts.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'User I/O'
ORDER BY time_waited_micro DESC;""",
                )
            ],
        ),
        wait_script(
            "07_concurrency_waits.sql",
            "Concurrency wait class (latches, buffers, mutexes)",
            "Advanced",
            """Meaning: waits for shared memory structures.
Cause: hot blocks, sequence, library cache mutex, undo header.
Investigate: event name → specific script (14 buffer busy, 13 library cache).
Fix: reduce contention (reverse index, hash partition, fix parse) — not more CPUs first.""",
            "Pack-free.",
            [
                Query(
                    title="Concurrency events",
                    what="WAIT_CLASS = Concurrency.",
                    columns="EVENT, TIME_S.",
                    interpret="latch: cache buffers chains and buffer busy waits often travel together (hot block).",
                    problem="Concurrency #1 on a previously quiet system after a code deploy.",
                    action="Identify the hot object (ASH p1/p2 or V$SEGMENT_STATISTICS).",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'Concurrency'
ORDER BY time_waited_micro DESC;""",
                )
            ],
        ),
        wait_script(
            "08_commit_waits.sql",
            "Commit-related waits (log file sync primarily)",
            "Advanced",
            """Meaning: after COMMIT the session waits for redo to be durable.
Cause: LGWR slow, too many commits, poor redo I/O, adaptive log file sync.
Investigate: 17_log_file_sync + 12_Redo.
Fix: fewer commits, faster redo disks, fix LGWR issues — not larger SGA.""",
            "Pack-free.",
            [
                Query(
                    title="Commit class events",
                    what="WAIT_CLASS = Commit.",
                    columns="EVENT, AVG_MS.",
                    interpret="log file sync avg > 5-10ms is usually storage or commit storm.",
                    problem="Commit class dominates DB time.",
                    action="17 and redo generation rate.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'Commit'
OR     event IN ('log file sync','log file parallel write')
ORDER BY time_waited_micro DESC;""",
                )
            ],
        ),
        wait_script(
            "09_network_waits.sql",
            "Network wait class (SQL*Net)",
            "Intermediate",
            """Meaning: time in SQL*Net message to/from client is often idle
(wait for the user). SQL*Net more data to client can be chatty fetches.
Cause: chatty arraysize, WAN latency, broken firewall idle timeout.
Investigate: distinguish more data vs message from client (Idle).
Fix: arraysize, reduce round trips — do not tune storage.""",
            "Pack-free. message from client is Idle and excluded from 01; shown here for completeness.",
            [
                Query(
                    title="Network and SQL*Net",
                    what="Network class plus explicit SQL*Net events.",
                    columns="EVENT, TIME_S.",
                    interpret="more data to client high = large result sets or arraysize 1.",
                    problem="WAN users with huge more data waits after a report change.",
                    action="Increase arraysize / tune the report.",
                    caution="Safe. Do not treat message from client as a DB problem.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    sql="""SELECT inst_id, event, wait_class, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  wait_class = 'Network'
OR     event LIKE 'SQL*Net%'
ORDER BY time_waited_micro DESC;""",
                )
            ],
        ),
        wait_script(
            "10_cluster_waits.sql",
            "Cluster wait class (RAC global cache)",
            "Advanced",
            """Meaning: time waiting for another instance to send a block.
Cause: chatty blocks across RAC, poor interconnect, imbalance, sequence.
Investigate: 11_rac_waits and folder 15.
Fix: localize the workload, faster interconnect, reduce block ping — not more SGA first.""",
            "RAC where applicable. Pack-free for V$SYSTEM_EVENT.",
            [
                Query(
                    title="Cluster class events",
                    what="WAIT_CLASS = Cluster.",
                    columns="EVENT, TIME_S, AVG_MS.",
                    interpret="gc cr/current multi block / grant 2-way / 3-way breakdown matters.",
                    problem="Cluster class #1 after a node eviction or interconnect packet loss.",
                    action="15_RAC interconnect + service placement.",
                    caution="Safe. Empty on single instance.",
                    privileges="SELECT on GV_$SYSTEM_EVENT",
                    notes="RAC where applicable.",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  wait_class = 'Cluster'
ORDER BY time_waited_micro DESC;""",
                )
            ],
        ),
        wait_script(
            "11_rac_waits.sql",
            "Detailed RAC/global cache wait names",
            "Advanced",
            """Meaning: gc cr request = consistent read block needed from another inst.
gc current request = current mode (DML).
Cause: same block modified on multiple nodes (hot block, sequence, index leaf).
Investigate: V$INSTANCE_CACHE_TRANSFER, ASH p1 file/block.
Fix: partition, reverse key (careful), pin service to one node, increase sequence cache.""",
            "RAC where applicable.",
            [
                Query(
                    title="GC events and cache transfers",
                    what="Cluster events plus GV$INSTANCE_CACHE_TRANSFER.",
                    columns="EVENT, CR_BLOCKS, CURRENT_BLOCKS.",
                    interpret="High current transfers on one object = DML ping-pong.",
                    problem="Lost blocks / congested on interconnect stats (15_RAC).",
                    action="15_RAC/07-12.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$INSTANCE_CACHE_TRANSFER",
                    notes="RAC where applicable.",
                    sql="""SELECT inst_id, event,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event LIKE 'gc %'
ORDER BY time_waited_micro DESC;

SELECT instance, cr_block, current_block, lost, congested
FROM   gv$instance_cache_transfer
ORDER BY instance;""",
                )
            ],
        ),
        wait_script(
            "12_enqueue_waits.sql",
            "Enqueue (enq:) waits",
            "Advanced",
            """Meaning: enqueues are locks (TX, TM, SQ, HW, ST, CF, ...).
Cause: row locks, table locks, sequence, high water mark, space.
Investigate: event name → 10_Locks; SQ → sequence cache; HW → mass insert.
Fix: commit design, indexes on FK, sequence cache, don't use LOCK TABLE.""",
            "Pack-free.",
            [
                Query(
                    title="Enqueue events",
                    what="Events like enq:% from system and current sessions.",
                    columns="EVENT, TIME_S, CURRENT WAITERS.",
                    interpret="TX row lock contention is application locking. TM contention is often unindexed FK.",
                    problem="enq: TX #1 during a Forms-heavy period.",
                    action="10_Locks_Blocking.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$SESSION",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  event LIKE 'enq:%'
ORDER BY time_waited_micro DESC;

SELECT inst_id, sid, username, event, seconds_in_wait, blocking_session, sql_id, module
FROM   gv$session
WHERE  event LIKE 'enq:%'
ORDER BY seconds_in_wait DESC;""",
                )
            ],
        ),
        wait_script(
            "13_library_cache_waits.sql",
            "Library cache pin/lock/mutex waits",
            "Advanced",
            """Meaning: waiting to pin or lock a library cache object (SQL, package).
Cause: hard parse storm, invalidations, compiling packages, mutex on hot cursor.
Investigate: 07/15 child cursors, 17 hard parse, who is compiling.
Fix: stop mid-day compiles, share SQL, do not flush shared pool.
Possible Fix: increase shared pool only if advice + 4031 evidence supports it.""",
            "Pack-free.",
            [
                Query(
                    title="Library cache and mutex events",
                    what="Filters library cache / cursor: pin events.",
                    columns="EVENT, TIME_S, CURRENT SESSIONS.",
                    interpret="cursor: pin S wait on X is a hot cursor + parse.",
                    problem="These events #1 after a stats job or FLUSH SHARED_POOL.",
                    action="07_Performance_Tuning 15/17/23. 30_Advanced library cache.",
                    caution="Safe. Do not flush shared pool to 'fix' this.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$SESSION",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  event LIKE 'library cache%'
OR     event LIKE 'cursor: pin%'
OR     event LIKE 'kksfbc child completion%'
ORDER BY time_waited_micro DESC;

SELECT inst_id, sid, username, event, sql_id, module, seconds_in_wait
FROM   gv$session
WHERE  event LIKE 'library cache%'
OR     event LIKE 'cursor: pin%';""",
                )
            ],
        ),
        wait_script(
            "14_buffer_busy_waits.sql",
            "Buffer busy waits and hot segments",
            "Advanced",
            """Meaning: session needs a buffer that is busy (another session is
reading or modifying it).
Cause: hot tail of an index, small table concurrent DML, undo header, segment header.
Investigate: V$SEGMENT_STATISTICS buffer busy waits, ASH p1/p2 file# block#.
Fix: reverse/hash, increase sequence cache, partition, PCTFREE — application design.""",
            "Pack-free for segment stats.",
            [
                Query(
                    title="Buffer busy and hot segments",
                    what="System event + DBA_HIST optional skipped; uses V$SEGMENT_STATISTICS.",
                    columns="OBJECT, BUFFER_BUSY_WAITS.",
                    interpret="The object with the highest buffer busy waits is the hot segment.",
                    problem="A custom sequence-driven PK index leaf is hot.",
                    action="Increase sequence cache / reverse key only with a design review.",
                    caution="Safe. V$SEGSTAT is cheap enough with a filter.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, V_$SEGMENT_STATISTICS, DBA_OBJECTS",
                    sql="""SELECT inst_id, event, total_waits, ROUND(time_waited_micro/1e6,1) time_waited_s
FROM   gv$system_event
WHERE  event IN ('buffer busy waits','read by other session','latch: cache buffers chains');

SELECT
       o.owner,
       o.object_name,
       o.object_type,
       ss.value AS buffer_busy_waits
FROM   v$segment_statistics ss
JOIN   dba_objects o ON o.object_id = ss.obj#
WHERE  ss.statistic_name = 'buffer busy waits'
AND    ss.value > 0
ORDER BY ss.value DESC
FETCH FIRST 30 ROWS ONLY;""",
                )
            ],
        ),
        wait_script(
            "15_db_file_sequential_read.sql",
            "db file sequential read (single-block reads)",
            "Advanced",
            """Meaning: single-block read, typically index lookup or table by ROWID.
Possible Cause: lots of index access (normal OLTP), slow storage, poor clustering (many ROWID jumps), missing join efficiency.
How to Investigate: avg_ms (latency) vs total_waits (volume). ASH SQL_ID. clustering factor.
Possible Fix: if latency — storage. if volume — better index/join/SQL. Not 'add indexes' blindly.""",
            "Pack-free.",
            [
                Query(
                    title="Sequential read latency and current waiters",
                    what="System event + sessions waiting on it.",
                    columns="AVG_MS, SID, SQL_ID, P1 file P2 block.",
                    interpret="avg 1ms flash, 5-15ms spinning SAN, >20ms problem.",
                    problem="avg_ms jumped but wait count did not — storage regression.",
                    action="Confirm with storage metrics. Get SQL_ID from waiters.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$SESSION",
                    sql="""SELECT inst_id, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event = 'db file sequential read';

SELECT inst_id, sid, username, sql_id, module, p1 file#, p2 block#, seconds_in_wait
FROM   gv$session
WHERE  event = 'db file sequential read'
AND    status = 'ACTIVE';""",
                )
            ],
        ),
        wait_script(
            "16_db_file_scattered_read.sql",
            "db file scattered read (multiblock FTS/index fast full)",
            "Advanced",
            """Meaning: multiblock read for FTS or index fast full scan.
Possible Cause: missing/unusable index, bad plan, implicit conversion, reporting during OLTP.
How to Investigate: current waiters' SQL_ID → plan. Compare to 07/24.
Possible Fix: fix the plan. Increase db_file_multiblock_read_count is rarely the right prod fix.""",
            "Pack-free.",
            [
                Query(
                    title="Scattered read and waiters",
                    what="Event stats + active waiters.",
                    columns="AVG_MS, SQL_ID.",
                    interpret="High waits during business hours on an OLTP module = likely bad plan.",
                    problem="A new scattered-read SQL after stats gather.",
                    action="DISPLAY_CURSOR and 07/14 regressions.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$SESSION",
                    sql="""SELECT inst_id, total_waits,
       ROUND(time_waited_micro/1e6,1) time_waited_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event = 'db file scattered read';

SELECT inst_id, sid, username, sql_id, module, seconds_in_wait, p1, p2, p3
FROM   gv$session
WHERE  event = 'db file scattered read'
AND    status = 'ACTIVE';""",
                )
            ],
        ),
        wait_script(
            "17_log_file_sync.sql",
            "log file sync deep dive",
            "Advanced",
            """Meaning: session COMMIT waiting for LGWR to finish.
Possible Cause: (1) commit storm (2) slow redo I/O (3) LGWR CPU starve (4) Data Guard sync dest.
How to Investigate: compare log file sync vs log file parallel write avg. If both high → storage/standby. If sync high and parallel write low → scheduling/commit rate.
Possible Fix: batch commits, faster redo, NODELAY/async review for DG, isolate LGWR.""",
            "Pack-free. See also 12_Redo_Archive/14.",
            [
                Query(
                    title="Sync vs parallel write",
                    what="Compares the two LGWR-related events and commit rate.",
                    columns="SYNC_AVG_MS, PARALLEL_WRITE_AVG_MS, USER_COMMITS.",
                    interpret="parallel write ≈ storage time. sync - parallel write ≈ extra (CPU, posting).",
                    problem="sync 20ms, parallel write 2ms — not the disks; look at CPU/posting/commit rate.",
                    action="12_Redo generation + application commit frequency.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms,
       ROUND(time_waited_micro/1e6,1) time_s
FROM   gv$system_event
WHERE  event IN ('log file sync','log file parallel write','log file switch completion','log file switch (checkpoint incomplete)');

SELECT inst_id, name, value
FROM   gv$sysstat
WHERE  name IN ('user commits','user rollbacks','redo size','redo synch writes','redo synch time');""",
                )
            ],
        ),
        wait_script(
            "18_log_file_parallel_write.sql",
            "log file parallel write (LGWR I/O)",
            "Advanced",
            """Meaning: LGWR writing redo members.
Possible Cause: slow/uneven multiplexed members, remote sync dest, overloaded ASM.
How to Investigate: V$LOGFILE members on different devices; ASM latency (16_ASM).
Possible Fix: put members on fast isolated disks; fix the slow copy (one bad member slows all).""",
            "Pack-free.",
            [
                Query(
                    title="LGWR write event and redo members",
                    what="Event + V$LOGFILE locations.",
                    columns="AVG_MS, MEMBER path.",
                    interpret="One member on NFS and one on ASM flash will run at NFS speed.",
                    problem="avg_ms jumped after adding a multiplex member on slow storage.",
                    action="Relocate the slow member in a window.",
                    caution="Safe to query. Dropping a logfile member is a change.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, V_$LOGFILE, V_$LOG",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event = 'log file parallel write';

SELECT group#, status, type, member FROM v$logfile ORDER BY group#;""",
                )
            ],
        ),
        wait_script(
            "19_direct_path_reads.sql",
            "direct path read / direct path read temp",
            "Advanced",
            """Meaning: reads that bypass the buffer cache (serial FTS on large
tables, PX, temp reads).
Possible Cause: large FTS, hash join spill, parallel query.
How to Investigate: event name temp vs not. SQL_ID. PGA/TEMP usage.
Possible Fix: tune the SQL; increase PGA if spilling; do not disable direct path globally.""",
            "Pack-free.",
            [
                Query(
                    title="Direct path read events and waiters",
                    what="System events + current waiters.",
                    columns="EVENT, SQL_ID.",
                    interpret="direct path read temp = TEMP I/O (spill). direct path read = table/index FTS bypassing cache.",
                    problem="read temp high — hash/sort spill (14_TEMP).",
                    action="PGA workarea + SQL tune.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$SESSION",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event LIKE 'direct path read%';

SELECT inst_id, sid, username, event, sql_id, module, seconds_in_wait
FROM   gv$session
WHERE  event LIKE 'direct path read%';""",
                )
            ],
        ),
        wait_script(
            "20_direct_path_writes.sql",
            "direct path write / write temp",
            "Advanced",
            """Meaning: writes bypassing buffer cache (CTAS, insert append, temp).
Possible Cause: load jobs, temp spills, PDML.
How to Investigate: waiters' SQL. TEMP usage.
Possible Fix: tune or reschedule loads; check TEMP sizing.""",
            "Pack-free.",
            [
                Query(
                    title="Direct path write events",
                    what="System events + waiters.",
                    columns="EVENT, SQL_ID.",
                    interpret="write temp with huge TEMP usage = spill.",
                    problem="Direct writes saturating storage during an index rebuild.",
                    action="Reschedule rebuilds. See 14_TEMP.",
                    caution="Safe.",
                    privileges="SELECT on GV_$SYSTEM_EVENT, GV_$SESSION",
                    sql="""SELECT inst_id, event, total_waits,
       ROUND(time_waited_micro/1e6,1) time_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM   gv$system_event
WHERE  event LIKE 'direct path write%';

SELECT inst_id, sid, username, event, sql_id, module, seconds_in_wait
FROM   gv$session
WHERE  event LIKE 'direct path write%';""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
