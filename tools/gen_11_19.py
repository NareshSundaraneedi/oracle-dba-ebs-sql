#!/usr/bin/env python3
from _writer import Query, Script, write_many


def q(title, what, columns, interpret, problem, action, caution, privs, sql, notes=""):
    return Query(title, sql, what, columns, interpret, problem, action, caution, privs, notes)


def S(folder, file_name, purpose, difficulty, desc, queries, extra="", ebs="N/A", priv="SELECT_CATALOG_ROLE", notes_header=""):
    return Script(
        folder=folder,
        file_name=file_name,
        category=folder,
        purpose=purpose,
        difficulty=difficulty,
        production_use="YES",
        description=desc,
        queries=queries,
        extra_header=extra or notes_header,
        ebs=ebs,
        privileges=priv,
    )


def scripts():
    out = []
    # ----- 11 Memory -----
    out += [
        S("11_Memory", "01_sga_size.sql", "SGA size vs targets and in-memory use", "Basic",
          "Shows SGA_TARGET / MEMORY_TARGET and actual SGA size. Use after a memory change or ORA-04031.",
          [q("SGA parameters and V$SGA",
             "Reads parameters and V$SGA.",
             "SGA_MAX_SIZE, SGA_TARGET, VALUE.",
             "SGA_TARGET 0 with MEMORY_TARGET means AMM. ASMM uses SGA_TARGET > 0.",
             "SGA_TARGET far below SGA_MAX after a failed autotune. Huge unused SGA_MAX reserved from OS.",
             "Resize only in a window. On RAC resize per instance.",
             "Safe. Do not ALTER SYSTEM here.",
             "SELECT on V_$PARAMETER, V_$SGA",
             """SELECT name, display_value FROM v$parameter
WHERE name IN ('memory_target','memory_max_target','sga_target','sga_max_size','lock_sga','use_large_pages');
SELECT name, ROUND(value/1024/1024/1024,2) AS gb FROM v$sga;""")],
        S("11_Memory", "02_sga_components.sql", "SGA breakdown by pool", "Basic",
          "V$SGAINFO / V$SGASTAT component sizes.",
          [q("SGA components",
             "Reads GV$SGAINFO.",
             "NAME, BYTES, RESIZEABLE.",
             "Buffer cache + shared pool should dominate an OLTP SGA.",
             "Unexpectedly huge Java pool or streams pool on an EBS DB that does not use them.",
             "Tune the responsible parameter (java_pool_size, streams_pool_size) in a window.",
             "Safe.",
             "SELECT on GV_$SGAINFO",
             """SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb, resizeable
FROM gv$sgainfo ORDER BY inst_id, bytes DESC;""")],
        S("11_Memory", "03_buffer_cache.sql", "Buffer cache size, advice, and hit ratio caveats", "Intermediate",
          "Hit ratio is a weak KPI. Use advice and wait events. Difference vs 07 SQL buffer gets: this is cache health, not SQL ranking.",
          [q("Cache size, advice, default pool",
             "V$BUFFER_POOL, V$DB_CACHE_ADVICE, dirty buffers.",
             "SIZE_FOR_ESTIMATE, ESTD_PHYS_READS.",
             "Advice showing little improvement beyond current size means grow-the-cache will not fix I/O.",
             "Cache tiny vs working set and sequential/scattered reads dominate.",
             "Grow db_cache_size only if advice and I/O evidence agree. Prefer SQL tuning.",
             "Safe. Hit ratio query included with a warning.",
             "SELECT on V_$BUFFER_POOL, V_$DB_CACHE_ADVICE, V_$SYSSTAT",
             """SELECT name, block_size, current_size, buffers FROM v$buffer_pool;
SELECT size_for_estimate, size_factor, estd_physical_reads, estd_physical_read_time
FROM v$db_cache_advice WHERE name = 'DEFAULT' ORDER BY size_for_estimate;
SELECT ROUND(1 - (phys.value/NULLIF(dbacc.value,0)),4) AS cache_hit_ratio_weak_kpi
FROM v$sysstat phys, v$sysstat dbacc
WHERE phys.name = 'physical reads cache'
AND dbacc.name = 'session logical reads';""")],
        S("11_Memory", "04_shared_pool.sql", "Shared pool component detail (memory-focused)", "Intermediate",
          "Difference vs 07/21: this file is sizing/advice; 07/21 includes reserved list 4031 symptoms. Both are useful; start here for capacity, 07/21 for incidents.",
          [q("Shared pool resize and top chunks",
             "V$SGASTAT shared pool + advice.",
             "NAME, MB.",
             "sql area + library cache growth is normal with load. KGLH0 explosion can be child cursor issues.",
             "free memory near 0 AND request_failures (see 07/21).",
             "Do not flush. See 30 ORA-04031.",
             "Safe.",
             "SELECT on GV_$SGASTAT, GV_$SHARED_POOL_ADVICE",
             """SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb
FROM gv$sgastat WHERE pool = 'shared pool' AND bytes > 10*1024*1024
ORDER BY inst_id, mb DESC;
SELECT inst_id, shared_pool_size_for_estimate, estd_lc_time_saved
FROM gv$shared_pool_advice ORDER BY 1,2;""")],
        S("11_Memory", "05_large_pool.sql", "Large pool usage (PX, RMAN, UGA shared server)", "Intermediate",
          "Large pool is used by parallel query, RMAN buffers, and shared servers.",
          [q("Large pool stats",
             "V$SGASTAT pool=large pool.",
             "NAME, MB.",
             "free memory high is OK if PX is idle.",
             "PX running and large pool free memory 0 with PX waits.",
             "Raise large_pool_size or sga_target and let ASMM move memory.",
             "Safe.",
             "SELECT on GV_$SGASTAT",
             """SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb
FROM gv$sgastat WHERE pool = 'large pool' ORDER BY inst_id, mb DESC;""")],
        S("11_Memory", "06_java_pool.sql", "Java pool size — usually small on EBS DB tier", "Basic",
          "EBS Java runs on the app tier. A large java_pool_size in the DB is often leftover.",
          [q("Java pool",
             "V$SGASTAT java pool.",
             "MB.",
             "Few MB unused is fine.",
             "Multi-GB java pool wasting SGA on a DB that does not run Java stored procs.",
             "Reduce in a window if confirmed unused.",
             "Safe.",
             "SELECT on GV_$SGASTAT, V_$PARAMETER",
             """SELECT name, display_value FROM v$parameter WHERE name LIKE 'java_pool%';
SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb FROM gv$sgastat WHERE pool = 'java pool';""")],
        S("11_Memory", "07_streams_pool.sql", "Streams/GoldenGate pool", "Intermediate",
          "streams_pool_size is used by Streams and Integrated Extract/Replicat.",
          [q("Streams pool",
             "Parameter + V$SGASTAT.",
             "MB.",
             "0 if unused. GoldenGate integrated capture needs a sized pool.",
             "OGG errors about streams pool / memory.",
             "Size per GoldenGate MOS notes — not guessed.",
             "Safe.",
             "SELECT on V_$PARAMETER, GV_$SGASTAT",
             """SELECT name, display_value FROM v$parameter WHERE name LIKE 'streams_pool%';
SELECT inst_id, name, ROUND(bytes/1024/1024,1) mb FROM gv$sgastat WHERE pool LIKE '%streams%';""")],
        S("11_Memory", "08_inmemory_area.sql", "In-Memory column store area (if licensed/enabled)", "Advanced",
          "INMEMORY_SIZE > 0 means the IM area is carved from SGA. Requires Database In-Memory option.",
          [q("In-Memory parameters and usage",
             "Parameters + V$INMEMORY_AREA if present.",
             "INMEMORY_SIZE, ALLOCATED, USED.",
             "No rows in V$INMEMORY_AREA if IM is off.",
             "IM enabled accidentally consuming SGA from buffer cache.",
             "Do not enable IM without a license and a plan.",
             "Safe. View missing if component unused — comment if ORA-00942.",
             "SELECT on V_$PARAMETER, V_$INMEMORY_AREA",
             """SELECT name, display_value FROM v$parameter WHERE name LIKE 'inmemory%';
-- SELECT pool, ROUND(alloc_bytes/1024/1024,1) alloc_mb, ROUND(used_bytes/1024/1024,1) used_mb
-- FROM v$inmemory_area;""",
             "In-Memory option. Oracle 19c.")]),
        S("11_Memory", "09_pga_target.sql", "PGA targets and limit", "Basic",
          "pga_aggregate_target is a goal. pga_aggregate_limit (12c+) is a hard cap (ORA-04036).",
          [q("PGA parameters",
             "V$PARAMETER PGA settings.",
             "PGA_AGGREGATE_TARGET, PGA_AGGREGATE_LIMIT, WORKAREA_SIZE_POLICY.",
             "WORKAREA_SIZE_POLICY should be AUTO on 19c.",
             "LIMIT too close to TARGET causing 4036 during month-end.",
             "Raise LIMIT carefully (it is a cap on process PGA, affects OS RAM).",
             "Safe.",
             "SELECT on V_$PARAMETER",
             """SELECT name, display_value FROM v$parameter
WHERE name IN ('pga_aggregate_target','pga_aggregate_limit','workarea_size_policy','hash_area_size','sort_area_size','memory_target');""")],
        S("11_Memory", "10_pga_usage.sql", "Current PGA aggregate usage vs target", "Intermediate",
          "V$PGASTAT is the instance view of PGA health.",
          [q("PGASTAT",
             "Reads GV$PGASTAT key rows.",
             "aggregate PGA target, total PGA allocated, over allocation count.",
             "over allocation count > 0 means target was exceeded.",
             "total PGA allocated >> target plus temp spills (14_TEMP).",
             "Tune SQL workareas or raise target after OS headroom check.",
             "Safe.",
             "SELECT on GV_$PGASTAT",
             """SELECT inst_id, name, value FROM gv$pgastat
WHERE name IN (
  'aggregate PGA target parameter','aggregate PGA auto target','total PGA allocated',
  'total PGA inuse','maximum PGA allocated','over allocation count',
  'extra bytes read/written','cache hit percentage','process count')
ORDER BY inst_id, name;""")],
        S("11_Memory", "11_pga_by_session.sql", "PGA by session (memory folder copy of session view)", "Intermediate",
          "Same join as 06/12. Kept here so memory investigations do not jump folders. Use 06/12 when the ticket is 'who'; use this when the ticket is 'PGA'.",
          [q("Session PGA",
             "GV$PROCESS joined to sessions.",
             "PGA_USED_MB, SQL_ID.",
             "A few hundred MB can be normal for a hash join. Multi-GB is a suspect.",
             "One session near pga_aggregate_limit.",
             "Identify SQL. Kill only as last resort (generate in 06).",
             "Safe.",
             "SELECT on GV_$SESSION, GV_$PROCESS",
             """SELECT s.inst_id, s.sid, s.serial#, s.username, s.module, s.sql_id,
       ROUND(p.pga_used_mem/1024/1024,1) pga_used_mb,
       ROUND(p.pga_alloc_mem/1024/1024,1) pga_alloc_mb
FROM gv$session s JOIN gv$process p ON p.inst_id=s.inst_id AND p.addr=s.paddr
WHERE s.type='USER' ORDER BY p.pga_alloc_mem DESC FETCH FIRST 40 ROWS ONLY;""")],
        S("11_Memory", "12_top_pga_consumers.sql", "Top PGA processes including background", "Intermediate",
          "Includes background processes (can matter for PX slaves).",
          [q("Top processes by PGA",
             "GV$PROCESS ordered by alloc.",
             "SPID, PROGRAM, PGA_ALLOC_MB.",
             "Many PX slaves each with large PGA multiply quickly.",
             "Sum of top processes ≈ pga_aggregate_limit.",
             "Reduce parallel degree or workarea.",
             "Safe.",
             "SELECT on GV_$PROCESS",
             """SELECT inst_id, spid, program,
       ROUND(pga_used_mem/1024/1024,1) used_mb,
       ROUND(pga_alloc_mem/1024/1024,1) alloc_mb,
       ROUND(pga_max_mem/1024/1024,1) max_mb
FROM gv$process ORDER BY pga_alloc_mem DESC FETCH FIRST 30 ROWS ONLY;""")],
        S("11_Memory", "13_pga_aggregate_statistics.sql", "PGA advice and workarea histogram", "Advanced",
          "V$PGA_TARGET_ADVICE estimates extra cache hits if PGA grows.",
          [q("PGA advice",
             "V$PGA_TARGET_ADVICE and V$PGA_TARGET_ADVICE_HISTOGRAM.",
             "PGA_TARGET_FOR_ESTIMATE, ESTD_OVERALLOC_COUNT, ESTD_EXTRA_BYTES_RW.",
             "If extra bytes read/written drops a lot at 2x target, SQL is spilling.",
             "overalloc estimated at current size.",
             "Raise PGA or fix SQL. Confirm OS memory first.",
             "Safe. Advice is statistical.",
             "SELECT on V_$PGA_TARGET_ADVICE",
             """SELECT pga_target_for_estimate, pga_target_factor,
       estd_pga_cache_hit_percentage, estd_overalloc_count, estd_extra_bytes_rw
FROM v$pga_target_advice ORDER BY pga_target_for_estimate;""")],
        S("11_Memory", "14_workarea_usage.sql", "Active SQL workareas (sort/hash in PGA)", "Advanced",
          "V$SQL_WORKAREA_ACTIVE shows in-flight sort/hash. spilling = TEMP I/O.",
          [q("Active workareas",
             "GV$SQL_WORKAREA_ACTIVE.",
             "SID, OPERATION_TYPE, ACTUAL_MEM_USED, TEMPSEG_SIZE.",
             "TEMPSEG_SIZE > 0 means spill.",
             "Many hash workareas spilling during a concurrent program.",
             "14_TEMP + SQL tune. Increase PGA only if many one-pass/multi-pass in V$SQL_WORKAREA.",
             "Safe.",
             "SELECT on GV_$SQL_WORKAREA_ACTIVE",
             """SELECT inst_id, sid, sql_id, operation_type,
       ROUND(expected_size/1024/1024,1) expected_mb,
       ROUND(actual_mem_used/1024/1024,1) actual_mb,
       ROUND(tempseg_size/1024/1024,1) temp_mb,
       number_passes
FROM gv$sql_workarea_active
ORDER BY actual_mem_used DESC;""")],
          extra="Complements 14_TEMP. If this view is empty, workareas already finished."),
    ]

    # ----- 12 Redo -----
    out += [
        S("12_Redo_Archive", "01_redo_log_groups.sql", "Redo group configuration", "Basic",
          "Group/thread/size/status. Production typically 3+ groups per thread, multiplexed members.",
          [q("V$LOG groups",
             "V$LOG.",
             "GROUP#, THREAD#, BYTES, STATUS, ARCHIVED.",
             "CURRENT is active. ACTIVE still needed for instance recovery.",
             "Only 2 small groups on a busy EBS DB → excessive switches.",
             "Add groups / resize in a window. Never drop CURRENT.",
             "Safe.",
             "SELECT on V_$LOG",
             """SELECT group#, thread#, sequence#, ROUND(bytes/1024/1024) mb, members, archived, status, first_time
FROM v$log ORDER BY thread#, group#;""")],
        S("12_Redo_Archive", "02_redo_members.sql", "Redo member paths and status", "Basic",
          "Each group should have 2+ members on independent failure domains.",
          [q("V$LOGFILE",
             "Member list.",
             "GROUP#, MEMBER, STATUS.",
             "STATUS NULL is healthy. INVALID/STALE is a problem.",
             "Single member per group.",
             "ALTER DATABASE ADD LOGFILE MEMBER — change window.",
             "Safe.",
             "SELECT on V_$LOGFILE",
             """SELECT group#, status, type, member, is_recovery_dest_file FROM v$logfile ORDER BY group#, member;""")],
        S("12_Redo_Archive", "03_current_redo_log.sql", "Which redo group is CURRENT per thread", "Basic",
          "Quick check during log switch problems.",
          [q("CURRENT logs",
             "V$LOG STATUS=CURRENT.",
             "GROUP#, SEQUENCE#, FIRST_TIME.",
             "Sequence should be advancing. Stuck sequence = archiver or checkpoint hang.",
             "CURRENT group not changing for a long time on a busy DB (or changing every second).",
             "12/11 log switches + archiver.",
             "Safe.",
             "SELECT on V_$LOG",
             """SELECT thread#, group#, sequence#, ROUND(bytes/1024/1024) mb, status, first_time
FROM v$log WHERE status = 'CURRENT' ORDER BY thread#;""")],
        S("12_Redo_Archive", "04_redo_log_status.sql", "All group statuses including CLEARING/UNUSED", "Basic",
          "CLEARING after an incomplete recovery. UNUSED after add.",
          [q("Status histogram",
             "Count by status.",
             "STATUS, CNT.",
             "Multiple CURRENT on one thread is wrong (except transient).",
             "CLEARING stuck.",
             "Alert log. Do not clear logs without Support if in doubt.",
             "Safe.",
             "SELECT on V_$LOG",
             """SELECT status, COUNT(*) cnt FROM v$log GROUP BY status;
SELECT * FROM v$log ORDER BY thread#, group#;""")],
        S("12_Redo_Archive", "05_redo_generation_rate.sql", "Redo generation rate from V$SYSSTAT / archived logs", "Advanced",
          "Estimates MB/hour. Needed before resizing redo (target: switches every 15-30 min under peak, not every 30 seconds).",
          [q("Redo size and recent archive volume",
             "SYSSTAT redo size + V$ARCHIVED_LOG last 24h.",
             "REDO_MB, ARCH_MB_24H, SWITCHES.",
             "Archive volume ≈ redo volume on primary.",
             ">1 log switch/minute sustained.",
             "Increase redo size or reduce generation (unnecessary indexes, supplemental log).",
             "Safe.",
             "SELECT on GV_$SYSSTAT, V_$ARCHIVED_LOG",
             """SELECT inst_id, ROUND(value/1024/1024,1) redo_mb_since_start
FROM gv$sysstat WHERE name = 'redo size';
SELECT COUNT(*) switches_24h,
       ROUND(SUM(blocks*block_size)/1024/1024,1) arch_mb_24h
FROM v$archived_log
WHERE first_time > SYSDATE-1 AND dest_id = 1;""")],
        S("12_Redo_Archive", "06_archive_destination.sql", "Archive destinations configuration", "Intermediate",
          "V$ARCHIVE_DEST shows local/remote dests including Data Guard.",
          [q("V$ARCHIVE_DEST",
             "Destinations and errors.",
             "DEST_ID, STATUS, DESTINATION, ERROR, VALID_TYPE.",
             "STATUS ERROR with a remote dest can stall the primary if LGWR SYNC.",
             "Local dest VALID but ERROR text populated.",
             "Fix space/network. Defer dest only with DG awareness.",
             "Safe.",
             "SELECT on V_$ARCHIVE_DEST",
             """SELECT dest_id, status, target, destination, valid_type, valid_role, db_unique_name, error
FROM v$archive_dest WHERE status <> 'INACTIVE' ORDER BY dest_id;""")],
        S("12_Redo_Archive", "07_archive_log_status.sql", "Recent archived logs and completion", "Intermediate",
          "V$ARCHIVED_LOG for last-day inventory.",
          [q("Recent archived logs",
             "Last 24h logs.",
             "SEQUENCE#, FIRST_TIME, NEXT_TIME, DELETED, STANDBY.",
             "DELETED YES means RMAN already removed them (need backups).",
             "Gap in sequence numbers.",
             "17_DataGuard archive gap if standby.",
             "Safe.",
             "SELECT on V_$ARCHIVED_LOG",
             """SELECT thread#, sequence#, dest_id,
       TO_CHAR(first_time,'DD-MON HH24:MI:SS') first_time,
       TO_CHAR(completion_time,'DD-MON HH24:MI:SS') completed,
       ROUND(blocks*block_size/1024/1024,1) mb,
       deleted, status, standby_dest
FROM v$archived_log
WHERE first_time > SYSDATE-1
ORDER BY thread#, sequence#, dest_id;""")],
        S("12_Redo_Archive", "08_archive_gap.sql", "Archive gaps (primary view of standby lag files)", "Advanced",
          "V$ARCHIVE_GAP on the standby shows missing sequences. On primary, compare dest apply.",
          [q("V$ARCHIVE_GAP and dest gap_status",
             "Gap views.",
             "THREAD#, LOW_SEQUENCE#, HIGH_SEQUENCE#.",
             "Any row is a gap that prevents apply.",
             "Gap growing — transport broken.",
             "17_DataGuard. Restore missing archives from backup.",
             "Safe. Often empty on primary.",
             "SELECT on V_$ARCHIVE_GAP, V_$ARCHIVE_DEST_STATUS",
             """SELECT * FROM v$archive_gap;
SELECT dest_id, gap_status, status, destination, error
FROM v$archive_dest_status WHERE status <> 'INACTIVE';""")],
        S("12_Redo_Archive", "09_archive_errors.sql", "Destinations in ERROR / DEFERRED", "Intermediate",
          "Immediate production check when archiving hangs.",
          [q("Error dests",
             "STATUS not VALID.",
             "ERROR text.",
             "ORA-00257 is FRA/archive full.",
             "Any ERROR on dest 1 (local).",
             "Free FRA (02/08). Do not delete archive files at OS without RMAN.",
             "Safe.",
             "SELECT on V_$ARCHIVE_DEST",
             """SELECT dest_id, status, error, destination FROM v$archive_dest
WHERE status NOT IN ('INACTIVE','VALID') OR error IS NOT NULL;""")],
        S("12_Redo_Archive", "10_archive_generation.sql", "Archive generation per hour (capacity)", "Intermediate",
          "Hourly histogram for RMAN backup window and FRA sizing.",
          [q("Archives per hour",
             "Group V$ARCHIVED_LOG by hour.",
             "HOUR, MB, COUNT.",
             "Month-end hours should be in the capacity plan.",
             "A 10x spike hour — investigate redo-heavy batch.",
             "Size FRA and redo for that hour.",
             "Safe.",
             "SELECT on V_$ARCHIVED_LOG",
             """SELECT TO_CHAR(first_time,'DD-MON HH24') hr,
       COUNT(*) logs,
       ROUND(SUM(blocks*block_size)/1024/1024,1) mb
FROM v$archived_log
WHERE first_time > SYSDATE-3 AND dest_id=1
GROUP BY TO_CHAR(first_time,'DD-MON HH24')
ORDER BY MIN(first_time);""")],
        S("12_Redo_Archive", "11_log_switches.sql", "Log switch history from V$LOG_HISTORY", "Intermediate",
          "V$LOG_HISTORY is switch history (control file).",
          [q("Recent switches",
             "Last 200 switches.",
             "SEQUENCE#, FIRST_TIME.",
             "Compute minutes between switches.",
             "Many switches < 1 minute apart.",
             "12 and 05. Increase redo size.",
             "Safe.",
             "SELECT on V_$LOG_HISTORY",
             """SELECT thread#, sequence#, first_time,
       ROUND((first_time - LAG(first_time) OVER (PARTITION BY thread# ORDER BY sequence#))*24*60,1) minutes_since_prev
FROM v$log_history
WHERE first_time > SYSDATE-1
ORDER BY thread#, sequence#;""")],
        S("12_Redo_Archive", "12_excessive_log_switches.sql", "Flag switch storms (< 2 minutes apart)", "Advanced",
          "Filters 11 for short gaps. Use during 'redo contention' or checkpoint incomplete.",
          [q("Switch storm",
             "Minutes_since_prev < 2.",
             "SEQUENCE#, MINUTES.",
             "Storms during index rebuilds or large loads are expected — reschedule.",
             "Storms during normal OLTP.",
             "Find redo-heavy SQL (07 top physical writes / redo).",
             "Safe.",
             "SELECT on V_$LOG_HISTORY",
             """WITH h AS (
  SELECT thread#, sequence#, first_time,
         (first_time - LAG(first_time) OVER (PARTITION BY thread# ORDER BY sequence#))*24*60 mins
  FROM v$log_history WHERE first_time > SYSDATE-1
)
SELECT * FROM h WHERE mins < 2 ORDER BY first_time;""")],
        S("12_Redo_Archive", "13_redo_contention.sql", "Redo allocation / copy latch and wait events", "Advanced",
          "Historical redo allocation latch is less common with private strands, but log file switch (checkpoint incomplete) and redo copy still appear.",
          [q("Redo wait events",
             "System events redo/log file switch.",
             "EVENT, TIME_S.",
             "checkpoint incomplete = DBWR cannot keep up with switches.",
             "checkpoint incomplete during switch storms.",
             "Bigger redo + faster DBWR I/O + fewer switches.",
             "Safe.",
             "SELECT on GV_$SYSTEM_EVENT",
             """SELECT inst_id, event, total_waits, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$system_event
WHERE event LIKE 'log file%' OR event LIKE 'redo%'
ORDER BY time_waited_micro DESC;""")],
        S("12_Redo_Archive", "14_log_file_sync_analysis.sql", "Redo-folder companion to 09/17 log file sync", "Advanced",
          "Difference vs 09/17: adds commit rate and redo size together so the redo DBA can act without leaving the folder.",
          [q("Sync, write, commits, redo size",
             "Combines events and sysstat.",
             "AVG_MS, USER_COMMITS, REDO_SIZE.",
             "High commits + high sync = chatty transactions (EBS forms save).",
             "Same as 09/17 problem set.",
             "Application batching. Redo disk. DG SYNC dest.",
             "Safe.",
             "SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT",
             """SELECT inst_id, event, ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM gv$system_event WHERE event IN ('log file sync','log file parallel write');
SELECT inst_id, name, value FROM gv$sysstat
WHERE name IN ('user commits','redo size','redo synch writes');""")],
          extra="See 09_Wait_Events/17 for Meaning/Cause/Fix narrative."),
    ]

    # ----- 13 UNDO -----
    out += [
        S("13_UNDO", "01_undo_tablespaces.sql", "Undo tablespaces, files, and retention guarantee", "Basic",
          "Lists undo TS and whether RETENTION GUARANTEE is set (can cause ORA-30036 sooner).",
          [q("Undo TS inventory",
             "DBA_TABLESPACES contents UNDO.",
             "TABLESPACE_NAME, RETENTION, STATUS.",
             "RETENTION GUARANTEE means expired extents will not be reused — 01555 down, 30036 up.",
             "NO GUARANTEE with frequent 01555 or GUARANTEE with 30036.",
             "Pick one: more space, or accept the tradeoff.",
             "Safe.",
             "SELECT on DBA_TABLESPACES, DBA_DATA_FILES",
             """SELECT tablespace_name, status, retention, block_size
FROM dba_tablespaces WHERE contents = 'UNDO';
SELECT tablespace_name, file_name, ROUND(bytes/1024/1024/1024,2) gb, autoextensible
FROM dba_data_files WHERE tablespace_name IN (SELECT tablespace_name FROM dba_tablespaces WHERE contents='UNDO');""")],
        S("13_UNDO", "02_undo_usage.sql", "Undo extent status and file fill", "Intermediate",
          "ACTIVE/UNEXPIRED/EXPIRED breakdown. Difference vs 04/11: this is the undo DBA home view.",
          [q("Extent status",
             "DBA_UNDO_EXTENTS.",
             "STATUS, MB.",
             "EXPIRED reusable. Steal of UNEXPIRED risks 01555.",
             "EXPIRED ≈ 0 and files 95%+.",
             "Add file or finish long transactions (04).",
             "Safe.",
             "SELECT on DBA_UNDO_EXTENTS",
             """SELECT tablespace_name, status, COUNT(*) extents, ROUND(SUM(bytes)/1024/1024,1) mb
FROM dba_undo_extents GROUP BY tablespace_name, status;""")],
        S("13_UNDO", "03_active_undo.sql", "Who holds ACTIVE undo (open transactions)", "Advanced",
          "Joins V$TRANSACTION to sessions.",
          [q("Active transactions",
             "GV$TRANSACTION + GV$SESSION.",
             "USED_UREC, USED_UBLK, START_TIME, SID, SQL_ID.",
             "USED_UBLK large = a big uncommitted DML.",
             "A transaction open for hours with many waiters (locks) or 01555 victims.",
             "Ask for commit/rollback. DISCONNECT POST_TRANSACTION if appropriate.",
             "Safe. Do not kill a payroll post without approval.",
             "SELECT on GV_$TRANSACTION, GV_$SESSION",
             """SELECT t.inst_id, t.addr, t.status, t.start_date,
       t.used_ublk, t.used_urec, t.xid,
       s.sid, s.serial#, s.username, s.status sess_status,
       s.module, s.sql_id, s.event
FROM gv$transaction t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.ses_addr
ORDER BY t.used_ublk DESC;""")],
        S("13_UNDO", "04_long_running_transactions.sql", "Transactions open longer than &minutes", "Advanced",
          "Filters 03 by age. These are 01555 and lock factories.",
          [q("Long open TX",
             "START_DATE older than threshold.",
             "HOURS_OPEN, USED_UBLK, MODULE.",
             "EBS: a form in a transaction since morning.",
             "Hours-open TX + UNEXPIRED pressure.",
             "User contact. See 06_Sessions inactive.",
             "Safe.",
             "SELECT on GV_$TRANSACTION, GV_$SESSION",
             """DEFINE minutes = 30
SELECT s.inst_id, s.sid, s.serial#, s.username, s.module, s.status,
       t.start_date, ROUND((SYSDATE-t.start_date)*24,2) hours_open,
       t.used_ublk, s.sql_id
FROM gv$transaction t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.ses_addr
WHERE (SYSDATE-t.start_date)*24*60 >= &minutes
ORDER BY t.start_date;""")],
        S("13_UNDO", "05_ora_01555_investigation.sql", "Snapshot too old evidence (V$UNDOSTAT SSOLDERRCNT)", "Advanced",
          "Symptom: ORA-01555. This file gathers evidence. Full playbook: 30/07.",
          [q("SSOLDERRCNT and longest query",
             "V$UNDOSTAT.",
             "SSOLDERRCNT, MAXQUERYLEN, MAXQUERYID.",
             "MAXQUERYID is the long query that needed undo (victim or cause).",
             "SSOLDERRCNT > 0 in the incident window.",
             "Increase undo space/retention AND tune/schedule the long query. Killing others may not help.",
             "Safe.",
             "SELECT on V_$UNDOSTAT",
             """SELECT TO_CHAR(begin_time,'DD-MON HH24:MI') begin_time,
       undoblks, txncount, maxquerylen, maxqueryid,
       tuned_undoretention, ssolderrcnt, nospaceerrcnt
FROM v$undostat WHERE begin_time > SYSDATE-2
AND (ssolderrcnt>0 OR nospaceerrcnt>0 OR maxquerylen>3600)
ORDER BY begin_time DESC;""")],
          extra="Playbook structure in 30_Advanced_Troubleshooting/07_ora_01555_snapshot_too_old.sql"),
        S("13_UNDO", "06_undo_retention.sql", "undo_retention vs tuned retention vs guarantee", "Intermediate",
          "If tuned << configured, you are not achieving the retention because of space.",
          [q("Retention comparison",
             "Parameter + V$UNDOSTAT tuned.",
             "UNDO_RETENTION, TUNED, RETENTION clause.",
             "Need retention >= longest query/flashback + margin.",
             "Tuned collapsing below the longest concurrent program.",
             "Add space first, then raise undo_retention.",
             "Safe.",
             "SELECT on V_$PARAMETER, V_$UNDOSTAT, DBA_TABLESPACES",
             """SELECT name, value FROM v$parameter WHERE name LIKE 'undo%';
SELECT tablespace_name, retention FROM dba_tablespaces WHERE contents='UNDO';
SELECT MAX(tuned_undoretention) max_tuned, MIN(tuned_undoretention) min_tuned,
       MAX(maxquerylen) max_q
FROM v$undostat WHERE begin_time > SYSDATE-1;""")],
        S("13_UNDO", "07_undo_tuning.sql", "Sizing estimate from undo stats", "Advanced",
          "Rough undo size ≈ undo blocks/sec * block size * retention. This is an estimate, not a mandate.",
          [q("Undo generation rate",
             "Average undoblks per 10-min slot.",
             "AVG_UNDOBLKS, EST_MB_FOR_RETENTION.",
             "Use peak slots, not average, for month-end.",
             "Estimate >> current undo file size.",
             "Add datafiles. Do not shrink undo as a performance fix.",
             "Safe. Estimate only.",
             "SELECT on V_$UNDOSTAT, V_$PARAMETER",
             """WITH p AS (
  SELECT TO_NUMBER(value) ret FROM v$parameter WHERE name='undo_retention'
), b AS (
  SELECT TO_NUMBER(value) bs FROM v$parameter WHERE name='db_block_size'
)
SELECT ROUND(AVG(undoblks),1) avg_undoblks_per_slot,
       ROUND(MAX(undoblks),1) max_undoblks_per_slot,
       ROUND(MAX(undoblks)/600 * (SELECT ret FROM p) * (SELECT bs FROM b)/1024/1024,1) AS rough_mb_at_peak_for_retention
FROM v$undostat WHERE begin_time > SYSDATE-1;""")],
          extra="Slot length is typically 10 minutes in V$UNDOSTAT."),
    ]

    # ----- 14 TEMP -----
    out += [
        S("14_TEMP", "01_temp_usage.sql", "Temporary tablespace fill level", "Intermediate",
          "Instance TEMP usage. Alert bands on used/total.",
          [q("TEMP free space",
             "DBA_TEMP_FREE_SPACE + sort segment.",
             "TOTAL_GB, FREE_GB, USED_PCT, ALERT.",
             "<70 Normal, 70-85 Monitor, 85-95 Warning, >95 Critical.",
             "CRITICAL during a hash join — ORA-01652 imminent.",
             "Find session (02). Add tempfile if legitimately undersized.",
             "Safe.",
             "SELECT on DBA_TEMP_FREE_SPACE, GV_$SORT_SEGMENT",
             """SELECT tablespace_name,
       ROUND(tablespace_size/1024/1024/1024,2) total_gb,
       ROUND(free_space/1024/1024/1024,2) free_gb,
       ROUND((tablespace_size-free_space)*100/NULLIF(tablespace_size,0),1) used_pct,
       CASE
         WHEN (tablespace_size-free_space)*100/NULLIF(tablespace_size,0) > 95 THEN 'CRITICAL'
         WHEN (tablespace_size-free_space)*100/NULLIF(tablespace_size,0) > 85 THEN 'WARNING'
         WHEN (tablespace_size-free_space)*100/NULLIF(tablespace_size,0) > 70 THEN 'MONITOR'
         ELSE 'NORMAL' END alert_level
FROM dba_temp_free_space;""")],
        S("14_TEMP", "02_temp_usage_by_session.sql", "TEMP by session", "Intermediate",
          "Who is spilling. Difference vs 04/10: this is the TEMP home copy with SEGTYPE.",
          [q("GV$TEMPSEG_USAGE",
             "Session TEMP.",
             "SID, SQL_ID, MB, SEGTYPE.",
             "HASH vs SORT vs WORK.",
             "One session using most of TEMP.",
             "Tune SQL or increase PGA to avoid spill.",
             "Safe.",
             "SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION",
             """SELECT t.inst_id, t.sid, s.serial#, s.username, s.module, t.sql_id, t.segtype,
       ROUND(t.blocks*8/1024,1) mb
FROM gv$tempseg_usage t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.session_addr
ORDER BY t.blocks DESC;""")],
        S("14_TEMP", "03_temp_usage_by_sql.sql", "TEMP aggregated by SQL_ID", "Intermediate",
          "Finds the statement, not just the session (PX has many sessions per SQL).",
          [q("TEMP by SQL_ID",
             "Group tempseg usage.",
             "SQL_ID, MB, SESSIONS.",
             "PX slaves share a SQL_ID.",
             "A reporting SQL_ID consuming TEMP on all nodes.",
             "Plan + workarea. Reduce parallel if it increased spill.",
             "Safe.",
             "SELECT on GV_$TEMPSEG_USAGE",
             """SELECT sql_id, segtype, COUNT(*) sessions, ROUND(SUM(blocks)*8/1024,1) mb
FROM gv$tempseg_usage
GROUP BY sql_id, segtype
ORDER BY mb DESC;""")],
        S("14_TEMP", "04_temp_spills.sql", "Evidence of PGA workarea spills to TEMP", "Advanced",
          "Combines workarea active + sysstat physical reads direct temporary.",
          [q("Spills",
             "Workareas with TEMPSEG_SIZE plus sysstat.",
             "TEMP_MB, PASSES.",
             "number_passes > 1 is multi-pass (very expensive).",
             "Multi-pass hash joins during peak.",
             "Increase PGA or tune the join. 11_Memory/14.",
             "Safe.",
             "SELECT on GV_$SQL_WORKAREA_ACTIVE, GV_$SYSSTAT",
             """SELECT inst_id, sql_id, operation_type, number_passes,
       ROUND(tempseg_size/1024/1024,1) temp_mb
FROM gv$sql_workarea_active WHERE tempseg_size > 0;
SELECT inst_id, name, value FROM gv$sysstat
WHERE name LIKE '%temporary%';""")],
        S("14_TEMP", "05_sort_usage.sql", "Sort segment usage only", "Intermediate",
          "Filters TEMP to SEGTYPE SORT. Difference vs 06: hash vs sort have different knobs (join vs ORDER BY/GROUP BY/index create).",
          [q("SORT temp",
             "SEGTYPE='SORT'.",
             "SID, SQL_ID, MB.",
             "Index create and ORDER BY show here.",
             "Huge sort during CREATE INDEX online.",
             "Reschedule DDL. Check SORT_AREA / PGA.",
             "Safe.",
             "SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION",
             """SELECT t.inst_id, t.sid, s.username, t.sql_id, ROUND(t.blocks*8/1024,1) mb
FROM gv$tempseg_usage t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.session_addr
WHERE t.segtype = 'SORT' ORDER BY t.blocks DESC;""")],
        S("14_TEMP", "06_hash_usage.sql", "Hash workarea TEMP usage", "Intermediate",
          "SEGTYPE HASH — typical of HASH JOIN / HASH GROUP BY.",
          [q("HASH temp",
             "SEGTYPE='HASH'.",
             "SID, SQL_ID, MB.",
             "Bad join order → huge hash table → TEMP.",
             "Hash spill + high CPU on the same SQL.",
             "Fix cardinality / join. Not just add TEMP forever.",
             "Safe.",
             "SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION",
             """SELECT t.inst_id, t.sid, s.username, t.sql_id, ROUND(t.blocks*8/1024,1) mb
FROM gv$tempseg_usage t
JOIN gv$session s ON s.inst_id=t.inst_id AND s.saddr=t.session_addr
WHERE t.segtype = 'HASH' ORDER BY t.blocks DESC;""")],
        ),
    ]

    # ----- 15 RAC -----
    rac = "RAC where applicable. Queries are harmless on single instance (one inst_id)."
    out += [
        S("15_RAC", "01_cluster_status.sql", "cluster_database and instance membership", "Basic",
          "SQL-side cluster check. OS crsctl is still required for full CRS health.",
          [q("Cluster parameters and instances",
             "Parameter + GV$INSTANCE.",
             "CLUSTER_DATABASE, INST_ID, STATUS.",
             "One instance down is a cluster incident even if SQL to the surviving node works.",
             "cluster_database TRUE but only one instance OPEN.",
             "Check CRS/HAS on the down node. Do not start instance from SQL.",
             "Safe.",
             "SELECT on V_$PARAMETER, GV_$INSTANCE",
             """SELECT name, value FROM v$parameter WHERE name LIKE 'cluster%';
SELECT inst_id, instance_name, host_name, status, startup_time FROM gv$instance ORDER BY inst_id;""")], extra=rac),
        S("15_RAC", "02_instance_status.sql", "Per-instance status, blocked, logins", "Basic",
          "Difference vs 01: focuses on health flags (BLOCKED, LOGINS) not just membership.",
          [q("GV$INSTANCE health",
             "Status flags.",
             "STATUS, BLOCKED, LOGINS, ARCHIVER.",
             "BLOCKED YES is rare and serious.",
             "An instance MOUNTED while others OPEN.",
             "Alert log / CRS.",
             "Safe.",
             "SELECT on GV_$INSTANCE",
             """SELECT inst_id, instance_name, status, database_status, blocked, logins, archiver, shutdown_pending
FROM gv$instance ORDER BY inst_id;""")], extra=rac),
        S("15_RAC", "03_rac_services.sql", "Services, preferred instances, and running where", "Intermediate",
          "V$ACTIVE_SERVICES / DBA_SERVICES show where work should land.",
          [q("Services",
             "GV$SERVICES / V$ACTIVE_SERVICES.",
             "NAME, NETWORK_NAME, GOAL, BLOCKED.",
             "EBS often uses a dedicated batch service.",
             "Service running on the wrong node after failover and not failback.",
             "srvctl relocate service — OS, not SQL.",
             "Safe.",
             "SELECT on GV_$SERVICES, GV_$ACTIVE_SERVICES",
             """SELECT inst_id, name, network_name, creation_date FROM gv$services ORDER BY name, inst_id;
SELECT inst_id, name, blocked, goal FROM gv$active_services ORDER BY name, inst_id;""")], extra=rac),
        S("15_RAC", "04_instance_load.sql", "Load comparison: sessions, DB CPU, AAS-ish", "Advanced",
          "Compares instances so you can see imbalance.",
          [q("Per-instance load",
             "Sessions + time model.",
             "SESSIONS, DB_TIME_S, DB_CPU_S.",
             "Large imbalance after a service failover.",
             "One node 4x DB time of the other with equal CPU_COUNT.",
             "15/14 node imbalance + service distribution.",
             "Safe.",
             "SELECT on GV_$SESSION, GV_$SYS_TIME_MODEL",
             """SELECT inst_id, COUNT(*) sessions, SUM(DECODE(status,'ACTIVE',1,0)) active
FROM gv$session GROUP BY inst_id;
SELECT inst_id, stat_name, ROUND(value/1e6,1) seconds
FROM gv$sys_time_model WHERE stat_name IN ('DB time','DB CPU') ORDER BY inst_id;""")], extra=rac),
        S("15_RAC", "05_sessions_by_instance.sql", "User session spread", "Basic",
          "Simple count by inst_id for user sessions.",
          [q("User sessions per instance",
             "GV$SESSION type USER.",
             "INST_ID, CNT.",
             "Should roughly match service placement.",
             "All users on inst 1, inst 2 idle.",
             "SCAN/service/local TNS misconfig.",
             "Safe.",
             "SELECT on GV_$SESSION",
             """SELECT inst_id, COUNT(*) user_sessions,
       SUM(DECODE(status,'ACTIVE',1,0)) active
FROM gv$session WHERE type='USER' GROUP BY inst_id ORDER BY inst_id;""")], extra=rac),
        S("15_RAC", "06_sql_by_instance.sql", "Same SQL_ID elapsed by instance", "Advanced",
          "Finds SQL that is expensive only on one node (plan difference, data, or cache).",
          [q("GV$SQL by inst",
             "Group elapsed by sql_id, inst_id.",
             "SQL_ID, INST, ELA_S.",
             "Same plan_hash on both vs different.",
             "10x elapsed on one instance only.",
             "Check child plans per inst. Interconnect for that SQL.",
             "Safe.",
             "SELECT on GV_$SQL",
             """SELECT sql_id, inst_id, plan_hash_value, executions,
       ROUND(elapsed_time/1e6,1) ela_s
FROM gv$sql WHERE elapsed_time > 1e7
ORDER BY sql_id, inst_id;""")], extra=rac),
        S("15_RAC", "07_global_cache_waits.sql", "Global cache wait summary", "Advanced",
          "Cluster wait class rollup. See 09/10-11 for event meaning.",
          [q("Cluster waits per instance",
             "GV$SYSTEM_EVENT wait_class Cluster.",
             "EVENT, TIME_S, INST.",
             "Compare instances — one congested node.",
             "gc buffer busy / congested high.",
             "Interconnect + hot blocks.",
             "Safe.",
             "SELECT on GV_$SYSTEM_EVENT",
             """SELECT inst_id, event, ROUND(time_waited_micro/1e6,1) time_s,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms
FROM gv$system_event WHERE wait_class='Cluster'
ORDER BY time_s DESC;""")], extra=rac),
        S("15_RAC", "08_gc_cr_requests.sql", "GC CR (consistent read) traffic", "Advanced",
          "Meaning: reading a consistent version from another instance. Cause: read/write split across nodes on same blocks.",
          [q("CR events and cache fusion stats",
             "gc cr% events + V$SYSSTAT gc cr.",
             "EVENT, BLOCKS.",
             "High CR is common; high flush + CR may mean write-read ping.",
             "CR avg_ms high (interconnect latency).",
             "15/12 interconnect.",
             "Safe.",
             "SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT",
             """SELECT inst_id, event, total_waits, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$system_event WHERE event LIKE 'gc cr%'
ORDER BY time_s DESC;
SELECT inst_id, name, value FROM gv$sysstat WHERE name LIKE 'gc cr%' ORDER BY inst_id, name;""")], extra=rac),
        S("15_RAC", "09_gc_current_requests.sql", "GC current (DML) traffic", "Advanced",
          "Current-mode transfers are more expensive than CR. Hot index leaves and sequences show up here.",
          [q("Current events",
             "gc current% + sysstat.",
             "EVENT, TIME_S.",
             "Current 2-way/3-way grants vs blocks.",
             "gc current block busy on a sequence-driven PK.",
             "Increase sequence cache; localize DML via services.",
             "Safe.",
             "SELECT on GV_$SYSTEM_EVENT, GV_$SYSSTAT",
             """SELECT inst_id, event, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$system_event WHERE event LIKE 'gc current%'
ORDER BY time_s DESC;""")], extra=rac),
        S("15_RAC", "10_block_transfers.sql", "Cache transfer counts between instances", "Advanced",
          "GV$INSTANCE_CACHE_TRANSFER / GV$GC_ELEMENT style counts.",
          [q("Transfers",
             "GV$INSTANCE_CACHE_TRANSFER.",
             "INSTANCE, CR_BLOCK, CURRENT_BLOCK, LOST, CONGESTED.",
             "LOST > 0 is interconnect packet loss — OS/network priority.",
             "LOST or CONGESTED climbing.",
             "Netadmin + Jumbo frames/RDS review. Not an SQL tune first.",
             "Safe.",
             "SELECT on GV_$INSTANCE_CACHE_TRANSFER",
             """SELECT inst_id, instance, cr_block, current_block, data_request, lost, congested
FROM gv$instance_cache_transfer ORDER BY inst_id, instance;""")], extra=rac),
        S("15_RAC", "11_rac_blocking_sessions.sql", "Pointer to RAC lock script plus local check", "Advanced",
          "Re-exports the essential RAC blocking query so RAC on-call does not leave this folder. Full notes in 10/12.",
          [q("Cross-instance blockers",
             "blocking_instance <> inst_id.",
             "WAITER_INST, BLOCKER_INST.",
             "Root blocker instance is where you generate KILL @inst.",
             "Cross-instance chain during peak.",
             "10_Locks_Blocking/12.",
             "Safe.",
             "SELECT on GV_$SESSION",
             """SELECT w.inst_id waiter_inst, w.sid waiter, w.event, w.seconds_in_wait,
       w.blocking_instance, w.blocking_session, b.username, b.status, b.module
FROM gv$session w
JOIN gv$session b ON b.inst_id=w.blocking_instance AND b.sid=w.blocking_session
WHERE w.blocking_session IS NOT NULL
ORDER BY w.seconds_in_wait DESC;""")], extra=rac),
        S("15_RAC", "12_interconnect_checks.sql", "Interconnect devices and GC lost blocks", "Advanced",
          "SQL cannot ping the interconnect. This shows what Oracle thinks the interconnect is and lost-block stats.",
          [q("Cluster interconnects and losts",
             "GV$CLUSTER_INTERCONNECTS / GV$CONFIGURED_INTERCONNECTS + lost stats.",
             "IP_ADDRESS, IS_PUBLIC, LOST.",
             "IS_PUBLIC TRUE on the interconnect is a serious misconfig.",
             "Lost blocks > 0 or public interconnect.",
             "Fix HAIP/cluster_interconnects with the sysadmin. Bounce may be required.",
             "Safe.",
             "SELECT on GV_$CLUSTER_INTERCONNECTS, GV_$CONFIGURED_INTERCONNECTS, GV_$SYSSTAT",
             """SELECT inst_id, name, ip_address, is_public FROM gv$configured_interconnects;
SELECT inst_id, name, ip_address FROM gv$cluster_interconnects;
SELECT inst_id, name, value FROM gv$sysstat WHERE name IN ('gc blocks lost','gc cr blocks lost','gc current blocks lost');""")], extra=rac),
        S("15_RAC", "13_service_distribution.sql", "Sessions per service per instance", "Intermediate",
          "Validates that batch vs OLTP services are isolated.",
          [q("Service x instance",
             "GV$SESSION group by service_name, inst_id.",
             "SERVICE, INST, SESSIONS.",
             "A failover may pile both services on one node.",
             "Batch service on the OLTP node during peak.",
             "Relocate service (srvctl). SQL cannot relocate.",
             "Safe.",
             "SELECT on GV_$SESSION",
             """SELECT service_name, inst_id, COUNT(*) sessions
FROM gv$session GROUP BY service_name, inst_id
ORDER BY service_name, inst_id;""")], extra=rac),
        S("15_RAC", "14_node_imbalance.sql", "Combined imbalance score (sessions, DB time, GC)", "Advanced",
          "One-page RAC imbalance for the bridge.",
          [q("Imbalance snapshot",
             "Side-by-side inst metrics.",
             "SESSIONS, DB_TIME, GC_TIME.",
             "Investigate if one node has most DB time and most GC — might be the writer node.",
             "One node CPU 100%, the other idle, after a node crash.",
             "Check services, job class instance affinity, and TAF.",
             "Safe.",
             "SELECT on GV_$SESSION, GV_$SYS_TIME_MODEL, GV_$SYSTEM_EVENT",
             """SELECT inst_id, COUNT(*) sessions FROM gv$session GROUP BY inst_id;
SELECT inst_id, ROUND(value/1e6,1) db_time_s FROM gv$sys_time_model WHERE stat_name='DB time';
SELECT inst_id, ROUND(SUM(time_waited_micro)/1e6,1) cluster_wait_s
FROM gv$system_event WHERE wait_class='Cluster' GROUP BY inst_id;""")], extra=rac),
    ]

    # ----- 16 ASM -----
    asm = "ASM where applicable. Some views are richer when connected to the ASM instance (+ASM). From the RDBMS, V$ASM_* is usually populated."
    out += [
        S("16_ASM", "01_asm_diskgroups.sql", "Diskgroup inventory and state", "Basic",
          "STATE MOUNTED and TYPE EXTERNAL/NORMAL/HIGH.",
          [q("V$ASM_DISKGROUP",
             "Groups.",
             "NAME, STATE, TYPE, TOTAL_MB, FREE_MB.",
             "DISMOUNTED is an outage for files in that group.",
             "STATE not CONNECTED/MOUNTED.",
             "ASM instance / srvctl status diskgroup.",
             "Safe.",
             "SELECT on V_$ASM_DISKGROUP",
             """SELECT group_number, name, state, type, compatibility, database_compatibility,
       ROUND(total_mb/1024,2) total_gb, ROUND(free_mb/1024,2) free_gb, ROUND(usable_file_mb/1024,2) usable_gb
FROM v$asm_diskgroup ORDER BY name;""")], extra=asm),
        S("16_ASM", "02_diskgroup_usage.sql", "Usage with 70/85/95 bands using usable space", "Intermediate",
          "Use USABLE_FILE_MB for NORMAL/HIGH redundancy.",
          [q("Usage alerts",
             "Used percent of usable.",
             "USED_PCT, ALERT.",
             "EXTERNAL: usable ≈ free. NORMAL: usable accounts for mirror.",
             ">85% WARNING on DATA or FRA groups.",
             "Add disks or move data. Rebalance will start.",
             "Safe.",
             "SELECT on V_$ASM_DISKGROUP",
             """SELECT name, type,
       ROUND((1-usable_file_mb/NULLIF(total_mb,0))*100,1) used_pct_usable,
       CASE WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>95 THEN 'CRITICAL'
            WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>85 THEN 'WARNING'
            WHEN (1-usable_file_mb/NULLIF(total_mb,0))*100>70 THEN 'MONITOR'
            ELSE 'NORMAL' END alert_level
FROM v$asm_diskgroup;""")], extra=asm),
        S("16_ASM", "03_disk_usage.sql", "Per-disk size and used", "Intermediate",
          "Imbalanced disks indicate a rebalance needed or a new disk just added.",
          [q("V$ASM_DISK",
             "Disks.",
             "NAME, TOTAL_MB, FREE_MB, HEADER_STATUS.",
             "PROVISIONED / CANDIDATE are not in a group yet.",
             "One disk much fuller than peers in the same group.",
             "Check rebalance (07). Do not drop disks at peak.",
             "Safe.",
             "SELECT on V_$ASM_DISK",
             """SELECT group_number, disk_number, name, path, header_status, mode_status, state,
       ROUND(total_mb/1024,2) total_gb, ROUND(free_mb/1024,2) free_gb
FROM v$asm_disk ORDER BY group_number, disk_number;""")], extra=asm),
        S("16_ASM", "04_disk_status.sql", "Disks not ONLINE / HEADER not MEMBER", "Intermediate",
          "Failed disks are a redundancy incident.",
          [q("Unhealthy disks",
             "Filter bad statuses.",
             "HEADER_STATUS, MODE_STATUS, STATE.",
             "MISSING + FORCING is an emergency.",
             "Any disk not ONLINE in a mounted group.",
             "Storage path / multipath. Do not FORCE immediately.",
             "Safe.",
             "SELECT on V_$ASM_DISK",
             """SELECT name, path, header_status, mode_status, state, failgroup
FROM v$asm_disk
WHERE header_status NOT IN ('MEMBER','CANDIDATE','PROVISIONED')
   OR NVL(mode_status,'x') <> 'ONLINE'
   OR NVL(state,'x') <> 'NORMAL';""")], extra=asm),
        S("16_ASM", "05_failure_groups.sql", "Failure group layout", "Advanced",
          "NORMAL redundancy needs 2 FG; HIGH needs 3. Putting both disks of a mirror in one FG defeats redundancy.",
          [q("FG composition",
             "Group by failgroup.",
             "FAILGROUP, DISKS, GB.",
             "Uneven FG sizes cause imbalanced usable space.",
             "Only one FG on a NORMAL group.",
             "Fix layout with storage — planned outage.",
             "Safe.",
             "SELECT on V_$ASM_DISK",
             """SELECT group_number, failgroup, COUNT(*) disks, ROUND(SUM(total_mb)/1024,2) total_gb
FROM v$asm_disk WHERE header_status='MEMBER'
GROUP BY group_number, failgroup ORDER BY 1,2;""")], extra=asm),
        S("16_ASM", "06_asm_clients.sql", "Who is using the diskgroups", "Intermediate",
          "V$ASM_CLIENT lists databases (and ASM) connected.",
          [q("Clients",
             "V$ASM_CLIENT.",
             "DB_NAME, STATUS, SOFTWARE_VERSION.",
             "STATUS CONNECTED is healthy.",
             "A database missing after a crash.",
             "Check that instance's ASM communication / CSS.",
             "Safe.",
             "SELECT on V_$ASM_CLIENT",
             """SELECT inst_id, group_number, instance_name, db_name, status, software_version, compatible_version
FROM v$asm_client ORDER BY db_name, instance_name;""")], extra=asm),
        S("16_ASM", "07_asm_rebalance.sql", "Rebalance operations in progress", "Advanced",
          "V$ASM_OPERATION shows EST_MINUTES. I/O impact is real — do not power up to 11 on peak without a decision.",
          [q("ASM operations",
             "V$ASM_OPERATION.",
             "OPERATION, STATE, POWER, EST_MINUTES.",
             "REBAL RUNNING is expected after add/drop disk.",
             "REBAL hung (EST_MINUTES not moving, STATE WAIT).",
             "Check ASM alert. Adjust POWER in a controlled way (08).",
             "Safe. ALTER DISKGROUP REBALANCE is a change.",
             "SELECT on V_$ASM_OPERATION",
             """SELECT group_number, operation, state, power, actual, sofar, est_work, est_rate, est_minutes
FROM v$asm_operation;""")], extra=asm),
        S("16_ASM", "08_rebalance_power.sql", "Current power and how to change it (generated)", "Advanced",
          "POWER 0-n. Generated ALTER only.",
          [q("Power display and generate",
             "Current operations + generate command.",
             "POWER.",
             "Higher power finishes faster, more I/O impact.",
             "Rebalance killing OLTP I/O.",
             "WARNING: generated ALTER DISKGROUP ... REBALANCE POWER n;",
             "WARNING: Do not execute blindly.",
             "SELECT on V_$ASM_OPERATION, V_$ASM_DISKGROUP",
             """SELECT name, state FROM v$asm_diskgroup;
SELECT group_number, operation, power, est_minutes FROM v$asm_operation;
-- WARNING: Review carefully before executing.
-- SELECT 'ALTER DISKGROUP '||name||' REBALANCE POWER 2;' FROM v$asm_diskgroup;""")], extra=asm),
        S("16_ASM", "09_asm_attributes.sql", "Diskgroup attributes (compatible, au_size, thin_provisioned)", "Advanced",
          "COMPATIBLE.ASM / RDBMS must match your RU plan. AU_SIZE 4M is common on 12c+.",
          [q("V$ASM_ATTRIBUTE",
             "Attributes.",
             "NAME, VALUE.",
             "compatible.rdbms too high can block older instances.",
             "Unexpected thin_provisioned / sector size.",
             "Change attributes only with a plan (some require rebalance).",
             "Safe.",
             "SELECT on V_$ASM_ATTRIBUTE",
             """SELECT group_number, name, value FROM v$asm_attribute
WHERE name IN ('compatible.asm','compatible.rdbms','au_size','sector_size','thin_provisioned','disk_repair_time')
OR name LIKE 'cell%'
ORDER BY group_number, name;""")], extra=asm),
        S("16_ASM", "10_asm_disk_performance.sql", "Disk-level I/O stats from ASM", "Advanced",
          "V$ASM_DISK_IOSTAT / V$ASM_DISK performance columns. Find the slow disk.",
          [q("Disk I/O",
             "Reads/writes and errors.",
             "READS, WRITES, READ_ERRS, WRITE_ERRS, READ_TIME.",
             "One disk with errors or vastly higher time.",
             "READ_ERRS > 0.",
             "Replace/investigate that LUN. Do not rebalance onto a failing disk.",
             "Safe.",
             "SELECT on V_$ASM_DISK_STAT, V_$ASM_DISK",
             """SELECT name, path, reads, writes, read_errs, write_errs,
       ROUND(read_time,1) read_time, ROUND(write_time,1) write_time
FROM v$asm_disk_stat
ORDER BY read_errs DESC, write_errs DESC, read_time DESC;""")], extra=asm),
        S("16_ASM", "11_space_forecasting.sql", "Simple days-to-full estimate from two snapshots of FREE_MB", "Advanced",
          "ASM has no built-in growth table. This prints current free space and instructs you to compare to yesterday's spool. Optional AWR not used (pack).",
          [q("Current free snapshot",
             "Prints a dated snapshot you should save daily.",
             "NAME, USABLE_GB, SNAP_TIME.",
             "Save output; compute (free_yesterday-free_today) for a daily burn rate.",
             "Burn rate that exhausts usable in < 14 days.",
             "Add storage before 85%.",
             "Safe. Not a statistical forecast.",
             "SELECT on V_$ASM_DISKGROUP",
             """SELECT SYSDATE snap_time, name,
       ROUND(usable_file_mb/1024,2) usable_gb,
       ROUND(free_mb/1024,2) free_gb
FROM v$asm_diskgroup;
PROMPT Compare this spool to yesterday. days_left ≈ usable_gb / daily_burn_gb.""")], extra=asm),
    ]

    # ----- 17 DataGuard -----
    dg = "Data Guard where applicable. Run role-specific queries on the correct member. Broker commands are shown as comments (DGMGRL)."
    out += [
        S("17_DataGuard", "01_database_role.sql", "Confirm DATABASE_ROLE on this member", "Basic",
          "Never perform primary-only actions on a standby.",
          [q("Role",
             "V$DATABASE role columns.",
             "DATABASE_ROLE, OPEN_MODE, SWITCHOVER_STATUS.",
             "PRIMARY vs PHYSICAL STANDBY vs SNAPSHOT STANDBY.",
             "Role not what the runbook says.",
             "Stop. Verify broker. Do not open READ WRITE on a physical standby.",
             "Safe.",
             "SELECT on V_$DATABASE",
             """SELECT name, db_unique_name, database_role, open_mode, protection_mode, switchover_status, dataguard_broker
FROM v$database;""")], extra=dg),
        S("17_DataGuard", "02_protection_mode.sql", "Maximum Performance / Availability / Protection", "Intermediate",
          "SYNC + Maximum Protection can stall the primary if the standby is down.",
          [q("Protection mode and level",
             "V$DATABASE + dests.",
             "PROTECTION_MODE, PROTECTION_LEVEL.",
             "LEVEL can be lower than MODE when a dest is down.",
             "MODE MAXIMUM PROTECTION and LEVEL lower — primary at risk of shutdown.",
             "Fix the dest or change mode in a planned way (broker).",
             "Safe. ALTER DATABASE SET STANDBY not executed.",
             "SELECT on V_$DATABASE",
             """SELECT protection_mode, protection_level, database_role FROM v$database;""")], extra=dg),
        S("17_DataGuard", "03_transport_status.sql", "Redo transport (LNS/ARCH) health", "Advanced",
          "V$MANAGED_STANDBY / dest status on primary.",
          [q("Transport dests",
             "V$ARCHIVE_DEST_STATUS type PHYSICAL.",
             "STATUS, GAP_STATUS, SYNCHRONIZATION_STATUS.",
             "RESYNCHRONIZING after a gap.",
             "TRANSPORT-OFF / ERROR.",
             "Network, dest space, TNS. Alert log on both sides.",
             "Safe.",
             "SELECT on V_$ARCHIVE_DEST_STATUS",
             """SELECT dest_id, status, type, database_mode, recovery_mode, destination,
       gap_status, error, synchronization_status, synchronized
FROM v$archive_dest_status WHERE type <> 'LOCAL' OR dest_id > 1;""")], extra=dg),
        S("17_DataGuard", "04_apply_status.sql", "Apply / MRP running?", "Advanced",
          "On the standby: V$MANAGED_STANDBY process MRP0.",
          [q("Managed standby processes",
             "V$MANAGED_STANDBY.",
             "PROCESS, STATUS, SEQUENCE#, BLOCK#.",
             "MRP0 APPLYING_LOG is healthy apply. WAIT_FOR_LOG is idle waiting redo.",
             "No MRP0 process — apply stopped.",
             "ALTER DATABASE RECOVER MANAGED STANDBY ... is a change; prefer broker: DGMGRL EDIT/START.",
             "Safe to query.",
             "SELECT on V_$MANAGED_STANDBY",
             """SELECT process, pid, status, thread#, sequence#, block#, blocks, delay_mins
FROM v$managed_standby
ORDER BY process;""")], extra=dg),
        S("17_DataGuard", "05_apply_lag.sql", "Apply lag from V$DATAGUARD_STATS", "Advanced",
          "APPLY LAG is how far the standby data is behind.",
          [q("Apply lag",
             "V$DATAGUARD_STATS.",
             "NAME, VALUE, TIME_COMPUTED.",
             "Lag of seconds is normal. Minutes+ needs a ticket during OLTP.",
             "Apply lag growing while transport lag is small → apply problem (CPU, I/O, recovery SLAVE).",
             "Standby alert / MRP trace. Media recovery performance.",
             "Safe.",
             "SELECT on V_$DATAGUARD_STATS",
             """SELECT name, value, unit, time_computed, datum_time
FROM v$dataguard_stats
WHERE name IN ('apply lag','apply finish time','estimated startup time')
ORDER BY name;""")], extra=dg),
        S("17_DataGuard", "06_transport_lag.sql", "Transport lag", "Advanced",
          "TRANSPORT LAG is redo not yet received. Different from apply lag.",
          [q("Transport lag",
             "V$DATAGUARD_STATS transport lag.",
             "VALUE.",
             "Transport lag high + apply lag similar = network/LNS. Apply >> transport = apply issue.",
             "Transport lag growing.",
             "TNS, bandwidth, SYNC vs ASYNC, primary dest errors.",
             "Safe.",
             "SELECT on V_$DATAGUARD_STATS",
             """SELECT name, value, unit, time_computed FROM v$dataguard_stats
WHERE name IN ('transport lag','redo transport lag');""")], extra=dg),
        S("17_DataGuard", "07_archive_gap.sql", "Gaps on standby", "Advanced",
          "V$ARCHIVE_GAP on the standby. Difference vs 12/08: this is DG-context commentary.",
          [q("Gaps",
             "V$ARCHIVE_GAP.",
             "THREAD#, LOW, HIGH.",
             "Need those sequences restored and registered.",
             "Any gap.",
             "RMAN restore archivelog from backup; then apply resumes.",
             "Safe.",
             "SELECT on V_$ARCHIVE_GAP",
             """SELECT thread#, low_sequence#, high_sequence# FROM v$archive_gap;""")], extra=dg),
        S("17_DataGuard", "08_destination_status.sql", "All dests including local", "Intermediate",
          "Full dest picture for the primary.",
          [q("Dest status",
             "V$ARCHIVE_DEST_STATUS.",
             "DEST_ID, STATUS, ERROR.",
             "VALID + SYNCHRONIZED YES for SYNC dests.",
             "ERROR on remote dest.",
             "12/09 + broker show database.",
             "Safe.",
             "SELECT on V_$ARCHIVE_DEST_STATUS",
             """SELECT dest_id, dest_name, status, type, database_mode, recovery_mode,
       destination, error, gap_status, synchronized
FROM v$archive_dest_status ORDER BY dest_id;""")], extra=dg),
        S("17_DataGuard", "09_standby_status.sql", "Standby database view (role, recover, FSFO)", "Advanced",
          "Run on standby. Combines role, open mode, MRP, lag.",
          [q("Standby snapshot",
             "V$DATABASE + stats + MRP.",
             "ROLE, OPEN_MODE, LAG, MRP STATUS.",
             "ADG: OPEN READ ONLY + MRP running.",
             "SNAPSHOT STANDBY when you needed physical.",
             "CONVERT TO PHYSICAL via broker after snapshot work.",
             "Safe.",
             "SELECT on V_$DATABASE, V_$DATAGUARD_STATS, V_$MANAGED_STANDBY",
             """SELECT database_role, open_mode, switchover_status FROM v$database;
SELECT name, value FROM v$dataguard_stats;
SELECT process, status, sequence# FROM v$managed_standby WHERE process LIKE 'MRP%';""")], extra=dg),
        S("17_DataGuard", "10_mrp_status.sql", "MRP0 detail", "Advanced",
          "Apply process only.",
          [q("MRP",
             "PROCESS LIKE MRP%.",
             "STATUS, SEQUENCE#.",
             "WAIT_FOR_GAP is a gap. APPLYING_LOG is good.",
             "MRP not present.",
             "Start apply via DGMGRL: EDIT DATABASE ... SET STATE='APPLY-ON';",
             "Safe.",
             "SELECT on V_$MANAGED_STANDBY",
             """SELECT process, status, thread#, sequence#, block#, delay_mins, client_pid
FROM v$managed_standby WHERE process LIKE 'MRP%' OR process LIKE 'PR%';""")], extra=dg),
        S("17_DataGuard", "11_rfs_status.sql", "RFS processes (standby receivers)", "Advanced",
          "RFS receives redo from primary LNS/ARCH.",
          [q("RFS",
             "PROCESS LIKE RFS%.",
             "STATUS, SEQUENCE#.",
             "No RFS on standby while primary thinks it ships → network/listener.",
             "RFS idle and transport lag growing.",
             "Listener, TNS, firewall, password file.",
             "Safe.",
             "SELECT on V_$MANAGED_STANDBY",
             """SELECT process, status, thread#, sequence#, block#, client_process, client_pid
FROM v$managed_standby WHERE process LIKE 'RFS%';""")], extra=dg),
        S("17_DataGuard", "12_broker_status.sql", "Data Guard broker configuration (SQL + DGMGRL hints)", "Advanced",
          "V$DG_BROKER_CONFIG / V$DATAGUARD_CONFIG. DGMGRL SHOW CONFIGURATION is authoritative for enabledness.",
          [q("Broker views",
             "V$DATAGUARD_CONFIG and parameter DG_BROKER_START.",
             "DB_UNIQUE_NAME, PARENT.",
             "DG_BROKER_START FALSE means broker is off (SQL-only manage).",
             "Broker enabled but configuration ERROR (check DGMGRL).",
             "DGMGRL: SHOW CONFIGURATION; SHOW DATABASE verbose;",
             "Safe. DGMGRL not executed from SQL*Plus here.",
             "SELECT on V_$DATAGUARD_CONFIG, V_$PARAMETER",
             """SELECT name, value FROM v$parameter WHERE name IN ('dg_broker_start','dg_broker_config_file1','dg_broker_config_file2');
SELECT * FROM v$dataguard_config;
PROMPT DGMGRL (run from OS):
PROMPT   SHOW CONFIGURATION;
PROMPT   SHOW DATABASE verbose '<db_unique_name>';""")], extra=dg),
        S("17_DataGuard", "13_switchover_readiness.sql", "SWITCHOVER_STATUS and sessions", "Advanced",
          "SWITCHOVER_STATUS must be TO STANDBY on primary (or SESSIONS ACTIVE). Do not switchover if not ready.",
          [q("Switchover readiness",
             "V$DATABASE.SWITCHOVER_STATUS + user sessions.",
             "SWITCHOVER_STATUS, USER_SESSIONS.",
             "TO STANDBY = ready. SESSIONS ACTIVE = disconnect users first. NOT ALLOWED = not ready.",
             "NOT ALLOWED — do not attempt switchover.",
             "Resolve apply/transport. Use broker SWITCHOVER TO <standby> after a change window.",
             "Safe. No SWITCHOVER command executed.",
             "SELECT on V_$DATABASE, GV_$SESSION",
             """SELECT db_unique_name, database_role, switchover_status, open_mode FROM v$database;
SELECT COUNT(*) user_sessions FROM gv$session WHERE type='USER';
PROMPT If SESSIONS ACTIVE, disconnect application sessions before switchover.""")], extra=dg),
        S("17_DataGuard", "14_failover_readiness.sql", "Failover readiness and FSFO observer notes", "Advanced",
          "Failover is destructive to unapplied primary redo if the old primary is lost. This only checks configuration health.",
          [q("FSFO / failover-related flags",
             "V$DATABASE FS_FAILOVER columns if present + dest sync.",
             "FS_FAILOVER_STATUS, FS_FAILOVER_CURRENT_TARGET.",
             "UNOBSERVED means observer is down — FSFO will not fire.",
             "Observer down in a FSFO config.",
             "Restart observer. Do not FAILOVER from SQL without incident command.",
             "Safe. No FAILOVER executed.",
             "SELECT on V_$DATABASE",
             """SELECT database_role, protection_mode, fs_failover_status, fs_failover_current_target,
       fs_failover_observer_present, fs_failover_observer_host
FROM v$database;
PROMPT DGMGRL: SHOW FAST_START FAILOVER;""")], extra=dg),
    ]

    # ----- 18 Backup -----
    out += [
        S("18_Backup_Recovery", "01_rman_configuration.sql", "RMAN persistent configuration (from the DB)", "Intermediate",
          "V$RMAN_CONFIGURATION shows CONFIGURE settings stored in the control file.",
          [q("RMAN config",
             "V$RMAN_CONFIGURATION.",
             "NAME, VALUE.",
             "CONTROLFILE AUTOBACKUP should be ON. RETENTION POLICY must match FRA/backups.",
             "AUTOBACKUP OFF on production.",
             "Change via RMAN CONFIGURE — not SQL. Shown as prompt.",
             "Safe.",
             "SELECT on V_$RMAN_CONFIGURATION",
             """SELECT name, value FROM v$rman_configuration ORDER BY name;
PROMPT Review in RMAN: SHOW ALL;""")], extra="RMAN views require the database to be using RMAN (normal)."),
        S("18_Backup_Recovery", "02_rman_backups.sql", "Recent RMAN backup jobs", "Intermediate",
          "V$RMAN_BACKUP_JOB_DETAILS is the job-level view (11g+).",
          [q("Backup jobs 14 days",
             "Job details.",
             "START_TIME, STATUS, INPUT_TYPE, OUTPUT_BYTES.",
             "COMPLETED is healthy. COMPLETED WITH WARNINGS still needs a look.",
             "No successful FULL/DB INCR in the retention window.",
             "Open RMAN logs. Do not delete backups to 'make space' without a restore test plan.",
             "Safe.",
             "SELECT on V_$RMAN_BACKUP_JOB_DETAILS",
             """SELECT session_key, input_type, status,
       TO_CHAR(start_time,'DD-MON-RR HH24:MI') start_time,
       TO_CHAR(end_time,'DD-MON-RR HH24:MI') end_time,
       ROUND(input_bytes/1024/1024/1024,2) input_gb,
       ROUND(output_bytes/1024/1024/1024,2) output_gb,
       time_taken_display
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-14
ORDER BY start_time DESC;""")],
        S("18_Backup_Recovery", "03_backup_status.sql", "Latest backup per type", "Intermediate",
          "When was the last successful full, incremental, archivelog backup?",
          [q("Last success by input_type",
             "Max completed time.",
             "INPUT_TYPE, LAST_SUCCESS.",
             "Archivelog backups should be frequent (hours).",
             "Last full older than retention / policy.",
             "Run the missing backup in the approved window.",
             "Safe.",
             "SELECT on V_$RMAN_BACKUP_JOB_DETAILS",
             """SELECT input_type,
       MAX(CASE WHEN status LIKE 'COMPLETED%' THEN end_time END) last_success,
       MAX(end_time) last_any
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-30
GROUP BY input_type
ORDER BY input_type;""")],
        S("18_Backup_Recovery", "04_failed_backups.sql", "Failed / incomplete RMAN jobs", "Intermediate",
          "STATUS FAILED or RUNNING far too long.",
          [q("Failed jobs",
             "Filter status.",
             "STATUS, START_TIME, TIME_TAKEN.",
             "A failed archivelog backup plus FRA pressure is an outage waiting to happen.",
             "FAILED last night.",
             "RMAN log + dest space + tape/library.",
             "Safe.",
             "SELECT on V_$RMAN_BACKUP_JOB_DETAILS",
             """SELECT session_key, input_type, status, start_time, end_time, time_taken_display
FROM v$rman_backup_job_details
WHERE status NOT LIKE 'COMPLETED%'
AND start_time > SYSDATE-14
ORDER BY start_time DESC;""")],
        S("18_Backup_Recovery", "05_backup_duration.sql", "Backup runtime trend", "Intermediate",
          "Durations growing toward the backup window limit.",
          [q("Duration by day",
             "Jobs with elapsed seconds.",
             "START_TIME, ELAPSED_SECONDS, OUTPUT_GB.",
             "Runtime growing with database size is expected; sudden 3x is not.",
             "Backup still RUNNING into production peak.",
             "Tune channels/section size or move window. Do not kill RMAN mid-backup casually.",
             "Safe.",
             "SELECT on V_$RMAN_BACKUP_JOB_DETAILS",
             """SELECT start_time, input_type, status, elapsed_seconds,
       ROUND(output_bytes/1024/1024/1024,2) output_gb
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-14
ORDER BY start_time;""")],
        S("18_Backup_Recovery", "06_backup_size.sql", "Backup piece sizes from V$BACKUP_PIECE", "Intermediate",
          "Piece-level sizes for tape/capacity planning.",
          [q("Pieces",
             "V$BACKUP_PIECE last 7 days.",
             "SET_STAMP, BYTES, STATUS, HANDLE.",
             "DELETED pieces are gone from disk/tape inventory.",
             "Pieces STATUS EXPIRED (need CROSSCHECK).",
             "RMAN CROSSCHECK / DELETE EXPIRED — change, generated as prompt.",
             "Safe.",
             "SELECT on V_$BACKUP_PIECE",
             """SELECT set_stamp, set_count, piece#, status,
       ROUND(bytes/1024/1024/1024,2) gb,
       start_time, handle
FROM v$backup_piece
WHERE start_time > SYSDATE-7
ORDER BY start_time DESC;""")],
        S("18_Backup_Recovery", "07_archive_backup.sql", "Archivelog backup coverage", "Advanced",
          "Are there sequences since yesterday without a backup (needed for PITR)?",
          [q("Archived vs backed up",
             "V$ARCHIVED_LOG.BACKUP_COUNT / V$BACKUP_REDOLOG.",
             "SEQUENCE#, BACKUP_COUNT, DELETED.",
             "BACKUP_COUNT 0 and DELETED YES = unrecoverable gap.",
             "Unbacked archives deleted by FRA/RMAN policy.",
             "RMAN BACKUP ARCHIVELOG. Stop FRA auto-delete until backups succeed.",
             "Safe.",
             "SELECT on V_$ARCHIVED_LOG",
             """SELECT thread#, sequence#, first_time, backup_count, deleted, name
FROM v$archived_log
WHERE first_time > SYSDATE-2
AND dest_id = 1
AND NVL(backup_count,0) = 0
ORDER BY thread#, sequence#;""")],
        S("18_Backup_Recovery", "08_controlfile_backup.sql", "Control file autobackup and recent copies", "Intermediate",
          "Controlfile autobackup ON is mandatory on production. V$CONTROLFILE_COPY lists copies.",
          [q("Controlfile backups",
             "RMAN config + V$CONTROLFILE_RECORD_SECTION / copies.",
             "AUTOBACKUP, CONTROLFILE COPIES.",
             "Autobackup pieces live with the backup destination / FRA.",
             "AUTOBACKUP OFF or no recent controlfile backup.",
             "RMAN: CONFIGURE CONTROLFILE AUTOBACKUP ON; BACKUP CURRENT CONTROLFILE;",
             "Safe.",
             "SELECT on V_$RMAN_CONFIGURATION, V_$CONTROLFILE_COPY",
             """SELECT name, value FROM v$rman_configuration WHERE name LIKE '%CONTROLFILE%';
SELECT stamp, name, status, completion_time FROM v$controlfile_copy ORDER BY completion_time DESC FETCH FIRST 20 ROWS ONLY;""")],
        S("18_Backup_Recovery", "09_spfile_backup.sql", "SPFILE included in autobackup", "Basic",
          "SPFILE is backed up with controlfile autobackup. Confirm autobackup and that an SPFILE is in use.",
          [q("SPFILE and autobackup",
             "SPFILE parameter + autobackup config.",
             "SPFILE path, AUTOBACKUP.",
             "Started from PFILE means restore of SPFILE is a different path.",
             "No SPFILE and AUTOBACKUP OFF.",
             "Create SPFILE and enable autobackup in a window.",
             "Safe.",
             "SELECT on V_$PARAMETER, V_$RMAN_CONFIGURATION",
             """SELECT name, value FROM v$parameter WHERE name = 'spfile';
SELECT name, value FROM v$rman_configuration WHERE name LIKE '%AUTOBACKUP%';""")],
        S("18_Backup_Recovery", "10_recovery_catalog.sql", "Is a recovery catalog in use (from the target)", "Advanced",
          "The target does not always show catalog use. RC_* views exist only when connected to the catalog DB. This checks V$RMAN_STATUS comments and prompts.",
          [q("Catalog hints",
             "V$RMAN_BACKUP_JOB_DETAILS session info + prompt.",
             "SESSION_RECID.",
             "If you have a catalog, run RC views there (RC_DATABASE, RC_BACKUP_SET).",
             "Catalog DB down — backups may still succeed to control file but reports suffer.",
             "Connect RMAN to catalog and RESYNC.",
             "Safe. No catalog writes.",
             "SELECT on V_$RMAN_BACKUP_JOB_DETAILS",
             """SELECT session_key, start_time, input_type, status
FROM v$rman_backup_job_details WHERE start_time > SYSDATE-3 ORDER BY start_time DESC;
PROMPT On the catalog database (if used):
PROMPT   SELECT dbid, name, resetlogs_time FROM rc_database;
PROMPT   SELECT status, COUNT(*) FROM rc_backup_set GROUP BY status;""")],
        S("18_Backup_Recovery", "11_rman_validation.sql", "How to validate backups (commands only)", "Advanced",
          "RESTORE VALIDATE and BACKUP VALIDATE read backup pieces without restoring. They are I/O heavy — run in a window. Not auto-executed.",
          [q("Validation guidance",
             "Prints RMAN validate examples as comments and lists pieces to validate.",
             "HANDLE, STATUS.",
             "VALIDATE checks readability, not that you practiced a restore.",
             "Pieces STATUS AVAILABLE but never validated after tape library errors.",
             "WARNING: RMAN VALIDATE is I/O heavy. Run manually.",
             "WARNING: Not executed.",
             "SELECT on V_$BACKUP_PIECE",
             """SELECT handle, status, start_time, ROUND(bytes/1024/1024/1024,2) gb
FROM v$backup_piece
WHERE status = 'AVAILABLE'
AND start_time > SYSDATE-7
ORDER BY start_time DESC;
PROMPT RMAN (manual, change window):
PROMPT   RESTORE DATABASE VALIDATE;
PROMPT   RESTORE ARCHIVELOG FROM TIME 'SYSDATE-1' VALIDATE;
PROMPT   BACKUP VALIDATE DATABASE;""")],
        S("18_Backup_Recovery", "12_database_recoverability.sql", "Recoverability to a point in time (V$RECOVER_FILE / backup redologs)", "Advanced",
          "V$RECOVER_FILE rows mean a datafile needs recovery now (incident). For backup recoverability, check archivelog continuity + backup age.",
          [q("Current recover files and backup age",
             "V$RECOVER_FILE plus last backup.",
             "FILE#, ERROR, LAST_BACKUP.",
             "Any V$RECOVER_FILE row on an OPEN DB is a media recovery incident.",
             "Files in recover + no recent backup.",
             "RMAN RESTORE/RECOVER — incident command, not here.",
             "Safe to query.",
             "SELECT on V_$RECOVER_FILE, V_$RMAN_BACKUP_JOB_DETAILS, V_$DATAFILE",
             """SELECT * FROM v$recover_file;
SELECT file#, name, status FROM v$datafile WHERE status NOT IN ('SYSTEM','ONLINE');
SELECT MAX(end_time) last_completed_backup
FROM v$rman_backup_job_details
WHERE status LIKE 'COMPLETED%' AND input_type IN ('DB FULL','DB INCR','DATAFILE FULL','DATAFILE INCR');""")],
        S("18_Backup_Recovery", "13_restore_validation.sql", "RESTORE PREVIEW / VALIDATE workflow (manual)", "Advanced",
          "RESTORE DATABASE PREVIEW summarizes which backups RMAN would use. Read-only and useful before a real restore. I/O light vs VALIDATE.",
          [q("Preview guidance",
             "Documents PREVIEW. Lists latest backup set keys.",
             "SESSION_KEY, INPUT_TYPE.",
             "PREVIEW shows the recovery plan without doing it.",
             "PREVIEW reports a gap — recoverability broken.",
             "Restore missing backups/archivelogs. Do not run RESTORE DATABASE without a declared incident.",
             "WARNING: RESTORE without PREVIEW/VALIDATE in prod is dangerous. Not executed.",
             "SELECT on V_$RMAN_BACKUP_JOB_DETAILS",
             """SELECT session_key, input_type, status, start_time, output_device_type
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE-14
ORDER BY start_time DESC;
PROMPT RMAN (manual):
PROMPT   RESTORE DATABASE PREVIEW;
PROMPT   RESTORE DATABASE PREVIEW SUMMARY;""")],
        S("18_Backup_Recovery", "14_backup_retention.sql", "Retention policy vs FRA and obsolete backups", "Advanced",
          "REDUNDANCY vs RECOVERY WINDOW. Obsolete backups can fill FRA if DELETE OBSOLETE is not run.",
          [q("Retention config and FRA reclaimable",
             "RMAN config + FRA usage.",
             "RETENTION, PERCENT_SPACE_RECLAIMABLE.",
             "High reclaimable + full FRA means DELETE OBSOLETE / backup archivelog delete input is overdue.",
             "FRA critical and reclaimable high.",
             "RMAN DELETE OBSOLETE is destructive to old backups — run only if policy allows. Generated as prompt.",
             "WARNING: DELETE OBSOLETE is destructive. Not executed.",
             "SELECT on V_$RMAN_CONFIGURATION, V_$RECOVERY_AREA_USAGE",
             """SELECT name, value FROM v$rman_configuration WHERE name LIKE '%RETENTION%' OR name LIKE '%ARCHIVELOG%';
SELECT file_type, percent_space_used, percent_space_reclaimable, number_of_files
FROM v$recovery_area_usage;
PROMPT RMAN (manual, after confirming policy):
PROMPT   REPORT OBSOLETE;
PROMPT   DELETE NOPROMPT OBSOLETE;  -- WARNING destructive""")],
        ),
    ]

    # ----- 19 Auditing -----
    ua = "Oracle 19c unified auditing. On upgraded DBs, mixed-mode may still write to AUD$. UNIFIED_AUDIT_TRAIL can be large — always time-bound. Housekeeping: DBMS_AUDIT_MGMT."
    out += [
        S("19_Auditing_Security", "01_audit_configuration.sql", "Unified audit vs traditional audit_trail parameter", "Intermediate",
          "Shows whether unified auditing is enabled (AUDIT_TRAIL parameter plus UNIFIED_AUDIT option). Fresh 19c often has unified audit on.",
          [q("Audit configuration",
             "Parameters + V$OPTION Unified Auditing.",
             "AUDIT_TRAIL, UNIFIED_AUDITING option.",
             "UNIFIED and traditional can both be in mixed mode on upgrades.",
             "No audit trail on a regulated production DB.",
             "Enabling unified audit requires a relink/option — project work, not an incident toggle.",
             "Safe.",
             "SELECT on V_$PARAMETER, V_$OPTION",
             """SELECT name, value FROM v$parameter
WHERE name IN ('audit_trail','audit_sys_operations','unified_audit_sga_queue_size');
SELECT parameter, value FROM v$option WHERE parameter LIKE '%Audit%';""")], extra=ua),
        S("19_Auditing_Security", "02_audit_policies.sql", "All unified audit policies", "Intermediate",
          "AUDIT_UNIFIED_POLICIES lists policy definitions (enabled or not).",
          [q("Policy definitions",
             "AUDIT_UNIFIED_POLICIES.",
             "POLICY_NAME, AUDIT_OPTION, OBJECT_SCHEMA.",
             "ORA_SECURECONFIG and ORA_LOGON_FAILURES are common Oracle-supplied policies.",
             "No policies defined on a 19c DB that claims to be audited.",
             "CREATE AUDIT POLICY is a change — not executed.",
             "Safe.",
             "SELECT on AUDIT_UNIFIED_POLICIES",
             """SELECT policy_name, audit_option, audit_option_type, object_schema, object_name, object_type
FROM audit_unified_policies
ORDER BY policy_name, audit_option;""")], extra=ua),
        S("19_Auditing_Security", "03_enabled_policies.sql", "Which unified policies are enabled and on whom", "Intermediate",
          "AUDIT_UNIFIED_ENABLED_POLICIES is the enforcement list.",
          [q("Enabled policies",
             "AUDIT_UNIFIED_ENABLED_POLICIES.",
             "POLICY_NAME, ENABLED_OPT, ENTITY_NAME, SUCCESS, FAILURE.",
             "ENABLED_OPT BY USER / EXCEPT USER / ON USER.",
             "ORA_LOGON_FAILURES not enabled — failed logins not captured here.",
             "AUDIT POLICY ... ENABLE is a change.",
             "Safe.",
             "SELECT on AUDIT_UNIFIED_ENABLED_POLICIES",
             """SELECT policy_name, enabled_opt, entity_name, entity_type, success, failure
FROM audit_unified_enabled_policies
ORDER BY policy_name, entity_name;""")], extra=ua),
        S("19_Auditing_Security", "04_audit_trail_location.sql", "Where audit records live and AUDSYS storage", "Advanced",
          "Unified audit tables live in AUDSYS (often SYSAUX). Growth fills SYSAUX if not purged.",
          [q("AUDSYS segments and audit table",
             "DBA_SEGMENTS for AUDSYS + DBMS_AUDIT_MGMT trail properties if accessible.",
             "SEGMENT_NAME, SIZE_MB.",
             "AUD$UNIFIED is the typical unified table (internal name may vary by release).",
             "AUDSYS tens of GB and growing daily.",
             "See 06/07 for growth and purge. Do not TRUNCATE AUDSYS.",
             "Safe. Do not move tablespaces without MOS guidance.",
             "SELECT on DBA_SEGMENTS, DBA_USERS",
             """SELECT username, default_tablespace FROM dba_users WHERE username = 'AUDSYS';
SELECT segment_name, segment_type, tablespace_name, ROUND(bytes/1024/1024,1) mb
FROM dba_segments WHERE owner = 'AUDSYS'
ORDER BY bytes DESC;""")], extra=ua),
        S("19_Auditing_Security", "05_audit_records.sql", "Recent unified audit records (time-bounded)", "Advanced",
          "UNIFIED_AUDIT_TRAIL is the query view. Always filter by EVENT_TIMESTAMP. Output may contain sensitive SQL.",
          [q("Last 24 hours sample",
             "Time-bounded UNIFIED_AUDIT_TRAIL.",
             "EVENT_TIMESTAMP, DBUSERNAME, ACTION_NAME, OBJECT_NAME, RETURN_CODE.",
             "RETURN_CODE 0 success. Non-zero is a failure (1017 etc.).",
             "Unexpected DROP/TRUNCATE from a named user.",
             "Investigate the user/host. Do not disable audit to hide growth.",
             "Trail can be huge — 24h + FETCH FIRST. Treat as confidential.",
             "AUDIT_VIEWER or AUDIT_ADMIN",
             """SELECT event_timestamp, dbusername, userhost, action_name, object_schema, object_name,
       return_code, unified_audit_policies
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;""")], extra=ua),
        S("19_Auditing_Security", "06_audit_growth.sql", "Audit volume per day (capacity)", "Advanced",
          "Counts records per day. Housekeeping is required — unified audit does not purge itself.",
          [q("Daily volume",
             "Group by trunc(event_timestamp).",
             "DAY, RECORDS.",
             "A new policy can 10x volume overnight (DML audit on FND_USER).",
             "Millions of rows/day — SYSAUX risk.",
             "Narrow policies. Schedule 07 purge. Partitioning of the trail is 19c+ option via DBMS_AUDIT_MGMT.",
             "Query itself can be expensive — last 7 days only.",
             "AUDIT_VIEWER",
             """SELECT TRUNC(event_timestamp) day, COUNT(*) records
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
GROUP BY TRUNC(event_timestamp)
ORDER BY 1;""")], extra=ua),
        S("19_Auditing_Security", "07_audit_purge.sql", "Audit trail purge — generate DBMS_AUDIT_MGMT calls only", "Advanced",
          "WARNING: Purging audit is a compliance decision. This only generates the API. Set last_archive_timestamp after exporting to SIEM.",
          [q("Purge guidance",
             "Shows trail properties if available and prints purge examples as comments.",
             "N/A.",
             "Never purge until SIEM/archive has the records (SOX/PCI).",
             "SYSAUX full of audit and no archive timestamp set — purge will refuse or you will violate policy.",
             "WARNING: DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL is destructive to audit history.",
             "WARNING: Generated only.",
             "AUDIT_ADMIN",
             """PROMPT 1) Export / ship to SIEM
PROMPT 2) Set last archive timestamp
PROMPT 3) Clean
/*
BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    last_archive_time => SYSTIMESTAMP - INTERVAL '90' DAY);
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    use_last_arch_timestamp => TRUE);
END;
/
*/
PROMPT Also consider INIT_CLEANUP and CREATE_PURGE_JOB for ongoing housekeeping.""")], extra=ua),
        S("19_Auditing_Security", "08_login_auditing.sql", "Successful and failed logons", "Intermediate",
          "LOGON actions in unified audit. Difference vs 03_Users/17: this file is the audit-folder home and includes successes for pattern analysis.",
          [q("Logons last day",
             "ACTION_NAME LOGON.",
             "DBUSERNAME, USERHOST, RETURN_CODE, COUNT.",
             "Failed storms from one host = bad password in a config.",
             "Successes from an unexpected country/host for SYS.",
             "Fix credentials. Review network ACLs. Do not unlock without identifying the source.",
             "Time-bounded.",
             "AUDIT_VIEWER",
             """SELECT dbusername, userhost, return_code, COUNT(*) cnt
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
AND action_name = 'LOGON'
GROUP BY dbusername, userhost, return_code
ORDER BY cnt DESC
FETCH FIRST 80 ROWS ONLY;""")], extra=ua),
        S("19_Auditing_Security", "09_privileged_user_auditing.sql", "SYS/SYSTEM/DBA activity", "Advanced",
          "Privileged actions. audit_sys_operations writes SYS to the OS audit if traditional; unified policies may capture SYSDBA.",
          [q("Privileged users last 7 days",
             "Filter high-privilege usernames.",
             "DBUSERNAME, ACTION, OBJECT, TIMESTAMP.",
             "Expected patch-window SYS activity vs unexpected mid-day DROP.",
             "SYS DROP/TRUNCATE outside a window.",
             "Incident + forensics. Preserve the trail (do not purge).",
             "Confidential. Time-bounded.",
             "AUDIT_VIEWER",
             """SELECT event_timestamp, dbusername, userhost, action_name, object_schema, object_name, sql_text
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
AND dbusername IN ('SYS','SYSTEM','SYSKM','SYSBACKUP','SYSDG')
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;""")], extra=ua),
        S("19_Auditing_Security", "10_ddl_auditing.sql", "DDL statements in the unified trail", "Advanced",
          "CREATE/ALTER/DROP/TRUNCATE. High volume if you audit all DDL on EBS.",
          [q("Recent DDL",
             "Action names like CREATE%/ALTER%/DROP%/TRUNCATE.",
             "TIMESTAMP, USER, ACTION, OBJECT.",
             "A cluster of DROPs is a threat or a failed clone cleanup.",
             "DROP TABLE on a product schema.",
             "Restore from backup if confirmed. Revoke privileges.",
             "SQL_TEXT may be huge — truncated by the view.",
             "AUDIT_VIEWER",
             """SELECT event_timestamp, dbusername, action_name, object_schema, object_name
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '3' DAY
AND (action_name LIKE 'CREATE%' OR action_name LIKE 'ALTER%' OR action_name LIKE 'DROP%'
     OR action_name IN ('TRUNCATE TABLE','GRANT','REVOKE'))
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;""")], extra=ua),
        S("19_Auditing_Security", "11_dml_auditing.sql", "DML audit records (use only if a DML policy exists)", "Advanced",
          "DML audit on transactional EBS tables will flood the trail. This query is for targeted investigations.",
          [q("Recent DML audit",
             "INSERT/UPDATE/DELETE in the trail.",
             "USER, OBJECT, ACTION, COUNT.",
             "No rows usually means you are not auditing DML (good for volume).",
             "Unexpected DML audit volume after a policy change.",
             "Disable the overly broad policy (change control) after confirming SIEM coverage.",
             "Can be enormous — last 12 hours + group by.",
             "AUDIT_VIEWER",
             """SELECT object_schema, object_name, action_name, dbusername, COUNT(*) cnt
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '12' HOUR
AND action_name IN ('INSERT','UPDATE','DELETE','SELECT')
GROUP BY object_schema, object_name, action_name, dbusername
ORDER BY cnt DESC
FETCH FIRST 80 ROWS ONLY;""")], extra=ua),
        S("19_Auditing_Security", "12_failed_login_auditing.sql", "Failed logins only (1017/28000)", "Intermediate",
          "Difference vs 08: failures only, plus LOCKED accounts correlation.",
          [q("Failed logins",
             "RETURN_CODE in (1017,28000,28001).",
             "USERHOST, DBUSERNAME, CNT.",
             "28000 is locked account — often the result of 1017 storms.",
             "APPS 1017 from a concurrent node after a password change.",
             "Update the config / wallet. Unlock with approval.",
             "Safe.",
             "AUDIT_VIEWER / SELECT on DBA_USERS",
             """SELECT dbusername, userhost, return_code, COUNT(*) cnt,
       MIN(event_timestamp) first_seen, MAX(event_timestamp) last_seen
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
AND return_code IN (1017, 28000, 28001)
GROUP BY dbusername, userhost, return_code
ORDER BY cnt DESC;

SELECT username, account_status, lock_date FROM dba_users WHERE account_status LIKE '%LOCK%';""")], extra=ua),
        S("19_Auditing_Security", "13_data_access_auditing.sql", "SELECT audit / FGA-style access on sensitive objects", "Advanced",
          "Unified policies can audit SELECT on specific tables. Traditional FGA is DBA_FGA_AUDIT_TRAIL (EE). Both shown.",
          [q("Access audit and FGA trail",
             "SELECT actions on a bind object + FGA trail if present.",
             "DBUSERNAME, OBJECT, TIMESTAMP.",
             "Use for 'who read this table' investigations when a policy exists.",
             "Access from an unexpected program to a PII table.",
             "Revoke and incident process. Do not enable SELECT audit on all APPS tables.",
             "Define object_p. FGA view may be empty.",
             "AUDIT_VIEWER",
             """DEFINE object_p = FND_USER

SELECT event_timestamp, dbusername, userhost, action_name, object_schema, object_name
FROM unified_audit_trail
WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
AND object_name = '&object_p'
AND action_name IN ('SELECT','UPDATE','DELETE')
ORDER BY event_timestamp DESC
FETCH FIRST 200 ROWS ONLY;

SELECT timestamp, db_user, object_schema, object_name, sql_text
FROM dba_fga_audit_trail
WHERE timestamp > SYSDATE-7
AND object_name = '&object_p'
FETCH FIRST 100 ROWS ONLY;""")], extra=ua + " Fine Grained Auditing is Enterprise Edition."),
    ]

    return out


if __name__ == "__main__":
    print(write_many(scripts()))
