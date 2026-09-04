#!/usr/bin/env python3
from _writer import Query, Script, write_many


def scripts():
    return [
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="01_tablespace_usage.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Tablespace used percent with 70/85/95 alert bands including autoextend headroom",
            difficulty="Intermediate",
            production_use="YES",
            description="""Primary daily space dashboard. Reports used% of allocated size AND
used% of MAXSIZE so autoextend does not hide a real limit.""",
            queries=[
                Query(
                    title="Tablespace usage vs allocated and vs maxsize",
                    what="Computes used/alloc and used/max for permanent tablespaces.",
                    columns="USED_PCT_ALLOC, USED_PCT_MAX, ALERT_LEVEL.",
                    interpret="<70 Normal, 70-85 Monitor, 85-95 Warning, >95 Critical — apply to USED_PCT_MAX for autoextend files.",
                    problem="CRITICAL on SYSTEM, SYSAUX, UNDO, or an EBS product tablespace before a payroll/month-end run.",
                    action="Add a datafile or raise MAXSIZE. Then find the growing segment (13_segment_growth.sql).",
                    caution="Safe. Adding files is a change.",
                    privileges="SELECT on DBA_TABLESPACES, DBA_DATA_FILES, DBA_FREE_SPACE",
                    sql="""WITH alloc AS (
       SELECT tablespace_name,
              SUM(bytes) alloc_bytes,
              SUM(DECODE(autoextensible,'YES',maxbytes,bytes)) max_bytes
       FROM   dba_data_files
       GROUP BY tablespace_name
),
free AS (
       SELECT tablespace_name, SUM(bytes) free_bytes
       FROM   dba_free_space
       GROUP BY tablespace_name
)
SELECT
       ts.tablespace_name,
       ts.status,
       ROUND(a.alloc_bytes/1024/1024/1024,2) alloc_gb,
       ROUND((a.alloc_bytes-NVL(f.free_bytes,0))/1024/1024/1024,2) used_gb,
       ROUND(NVL(f.free_bytes,0)/1024/1024/1024,2) free_gb,
       ROUND(a.max_bytes/1024/1024/1024,2) max_gb,
       ROUND((a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.alloc_bytes,0),1) used_pct_alloc,
       ROUND((a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0),1) used_pct_max,
       CASE
         WHEN (a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0) > 95 THEN 'CRITICAL'
         WHEN (a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0) > 85 THEN 'WARNING'
         WHEN (a.alloc_bytes-NVL(f.free_bytes,0))*100/NULLIF(a.max_bytes,0) > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_tablespaces ts
JOIN   alloc a ON a.tablespace_name = ts.tablespace_name
LEFT JOIN free f ON f.tablespace_name = ts.tablespace_name
WHERE  ts.contents = 'PERMANENT'
ORDER BY used_pct_max DESC;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="02_tablespace_free_space.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Show free space chunks (fragmentation-aware)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Total free space can look healthy while the largest free chunk is too
small for the next extent (especially dictionary-managed or huge
uniform extents).""",
            queries=[
                Query(
                    title="Free space total vs largest chunk",
                    what="Aggregates DBA_FREE_SPACE per tablespace.",
                    columns="FREE_GB, LARGEST_CHUNK_MB, CHUNKS.",
                    interpret="Many tiny chunks + large next extent size = ORA-01653 / 01654 despite free space.",
                    problem="LARGEST_CHUNK_MB smaller than the next extent of a growing table.",
                    action="Coalesce is automatic for locally managed bitmap tablespaces. Add a datafile if the largest chunk is insufficient.",
                    caution="Safe.",
                    privileges="SELECT on DBA_FREE_SPACE",
                    sql="""SELECT
       tablespace_name,
       COUNT(*) AS free_chunks,
       ROUND(SUM(bytes)/1024/1024/1024,2) AS free_gb,
       ROUND(MAX(bytes)/1024/1024,1) AS largest_chunk_mb
FROM   dba_free_space
GROUP BY tablespace_name
ORDER BY largest_chunk_mb;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="03_tablespace_growth.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Estimate tablespace growth from AWR or DBA_HIST_TBSPC_SPACE_USAGE",
            difficulty="Advanced",
            production_use="YES",
            description="""Uses AWR history when licensed. Without Diagnostics Pack, use the
current size query in 01 and compare to last week's export of this output.""",
            extra_header="LICENSING: DBA_HIST_* requires Oracle Diagnostics Pack.",
            queries=[
                Query(
                    title="Tablespace growth over the last 14 days (AWR)",
                    what="Reads DBA_HIST_TBSPC_SPACE_USAGE joined to tablespace names.",
                    columns="TABLESPACE_NAME, DAYS, GROWTH_GB, DAILY_MB.",
                    interpret="Positive daily growth is normal. A step change means a load, index rebuild, or missing purge.",
                    problem="APPS_TS_TX_DATA growing tens of GB/day.",
                    action="Identify the segment (13/14). Schedule purge or add space before the weekend job.",
                    caution="Do not run against a large AWR retention without the time filter. Pack licensed.",
                    privileges="SELECT on DBA_HIST_TBSPC_SPACE_USAGE, DBA_HIST_SNAPSHOT, DBA_TABLESPACES",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       ts.tablespace_name,
       ROUND(MAX(su.tablespace_size * ts.block_size) / 1024 / 1024 / 1024, 2) AS end_alloc_gb,
       ROUND(MIN(su.tablespace_size * ts.block_size) / 1024 / 1024 / 1024, 2) AS start_alloc_gb,
       ROUND( (MAX(su.tablespace_usedsize * ts.block_size) - MIN(su.tablespace_usedsize * ts.block_size))
              / 1024 / 1024 / 1024, 2) AS used_growth_gb
FROM   dba_hist_tbspc_space_usage su
JOIN   v$tablespace vt ON vt.ts# = su.tablespace_id
JOIN   dba_tablespaces ts ON ts.tablespace_name = vt.name
JOIN   dba_hist_snapshot sn ON sn.snap_id = su.snap_id AND sn.dbid = su.dbid AND sn.instance_number = su.instance_number
WHERE  sn.begin_interval_time > SYSDATE - 14
GROUP BY ts.tablespace_name
ORDER BY used_growth_gb DESC NULLS LAST;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="04_datafile_usage.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Per-datafile allocated size and autoextend remaining",
            difficulty="Intermediate",
            production_use="YES",
            description="""File-level remaining growth. Complements tablespace totals when one
file is at MAXSIZE and others are not.""",
            queries=[
                Query(
                    title="Datafile headroom",
                    what="Computes remaining bytes to MAXSIZE per file.",
                    columns="FILE_NAME, SIZE_GB, MAX_GB, REMAINING_GB, AUTOEXTENSIBLE.",
                    interpret="AUTOEXTENSIBLE NO and tablespace 90% full means you must add a file, not wait for extend.",
                    problem="Remaining_GB < 1 on the only file in a tablespace.",
                    action="ALTER DATABASE DATAFILE ... AUTOEXTEND ON NEXT 1G MAXSIZE ... or add a file. Generated only.",
                    caution="WARNING: ALTER DATABASE DATAFILE generated only. MAXSIZE is limited by file system / ASM and BIGFILE vs smallfile (32GB typical smallfile 8k).",
                    privileges="SELECT on DBA_DATA_FILES",
                    sql="""SELECT
       file_id,
       tablespace_name,
       file_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb,
       autoextensible,
       ROUND(maxbytes/1024/1024/1024,2) AS max_gb,
       ROUND(DECODE(autoextensible,'YES',maxbytes-bytes,0)/1024/1024/1024,2) AS remaining_gb,
       CASE
         WHEN autoextensible = 'NO' THEN 'NO_AUTOEXTEND'
         WHEN maxbytes - bytes < 1024*1024*1024 THEN 'CRITICAL'
         WHEN maxbytes - bytes < 5*1024*1024*1024 THEN 'WARNING'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_data_files
ORDER BY remaining_gb, tablespace_name;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="05_autoextend_status.sql",
            category="04_Tablespaces_Datafiles",
            purpose="List files with autoextend off or unlimited maxsize",
            difficulty="Basic",
            production_use="YES",
            description="""UNLIMITED autoextend can fill an ASM diskgroup without a tablespace
alert firing at 85% allocated.""",
            queries=[
                Query(
                    title="Autoextend anomalies",
                    what="Flags AUTOEXTENSIBLE NO and MAXBYTES at the platform unlimited sentinel.",
                    columns="FILE_NAME, AUTOEXTENSIBLE, MAXBYTES.",
                    interpret="MAXBYTES of 34359721984 (32GB-ish) is the typical smallfile ceiling, not unlimited. 0 or huge values need review.",
                    problem="Autoextend ON MAXSIZE UNLIMITED on a diskgroup that is already 80% full.",
                    action="Set a finite MAXSIZE and monitor diskgroup space.",
                    caution="Safe.",
                    privileges="SELECT on DBA_DATA_FILES, DBA_TEMP_FILES",
                    sql="""SELECT 'DATA' AS file_kind, file_id, tablespace_name, autoextensible,
       ROUND(bytes/1024/1024/1024,2) size_gb,
       ROUND(maxbytes/1024/1024/1024,2) max_gb
FROM   dba_data_files
WHERE  autoextensible = 'NO'
OR     maxbytes = 0
OR     maxbytes >= 32*1024*1024*1024
UNION ALL
SELECT 'TEMP', file_id, tablespace_name, autoextensible,
       ROUND(bytes/1024/1024/1024,2),
       ROUND(maxbytes/1024/1024/1024,2)
FROM   dba_temp_files
WHERE  autoextensible = 'NO'
OR     maxbytes = 0
ORDER BY 1, 3, 2;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="06_maximum_datafile_size.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Explain smallfile vs bigfile maximum sizes",
            difficulty="Intermediate",
            production_use="YES",
            description="""Smallfile tablespaces are limited by block size * 4M blocks (~32GB at 8K).
Attempting to extend beyond that raises ORA-01237 / ORA-03206.""",
            queries=[
                Query(
                    title="Bigfile flag and current vs theoretical max",
                    what="Joins DBA_TABLESPACES.BIGFILE with file sizes.",
                    columns="BIGFILE, BLOCK_SIZE, SIZE_GB, MAX_GB.",
                    interpret="BIGFILE YES can grow very large (32TB+ depending on block size). Smallfile needs more files, not a bigger MAXSIZE.",
                    problem="Trying to set MAXSIZE 100G on an 8K smallfile.",
                    action="Add another smallfile or convert strategy to bigfile for new tablespaces only (migration is a project).",
                    caution="Safe.",
                    privileges="SELECT on DBA_TABLESPACES, DBA_DATA_FILES",
                    sql="""SELECT
       ts.tablespace_name,
       ts.bigfile,
       ts.block_size,
       df.file_id,
       ROUND(df.bytes/1024/1024/1024,2) AS size_gb,
       ROUND(df.maxbytes/1024/1024/1024,2) AS max_gb,
       CASE WHEN ts.bigfile = 'NO' AND ts.block_size = 8192
            THEN 32 ELSE NULL END AS typical_smallfile_limit_gb
FROM   dba_tablespaces ts
JOIN   dba_data_files df ON df.tablespace_name = ts.tablespace_name
ORDER BY ts.tablespace_name, df.file_id;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="07_datafile_growth.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Show files that autoextended recently via alert or file size vs creation",
            difficulty="Advanced",
            production_use="YES",
            description="""V$DATAFILE.CREATE_BYTES vs BYTES shows growth since file creation.
For a time series, use AWR (licensed) or compare weekly snapshots.""",
            queries=[
                Query(
                    title="Datafile growth since creation",
                    what="Compares V$DATAFILE.BYTES to CREATE_BYTES.",
                    columns="FILE_NAME, CREATE_GB, CURRENT_GB, GROWN_GB.",
                    interpret="Large GROWN_GB on a recently added file means rapid load.",
                    problem="A file created yesterday already at MAXSIZE.",
                    action="Find the segment. Add space before the next batch window.",
                    caution="Safe. CREATE_BYTES is since the file was created, not since last week.",
                    privileges="SELECT on V_$DATAFILE, DBA_DATA_FILES",
                    sql="""SELECT
       d.file_id,
       d.tablespace_name,
       d.file_name,
       ROUND(v.create_bytes/1024/1024/1024,2) AS create_gb,
       ROUND(v.bytes/1024/1024/1024,2) AS current_gb,
       ROUND((v.bytes - v.create_bytes)/1024/1024/1024,2) AS grown_gb
FROM   dba_data_files d
JOIN   v$datafile v ON v.file# = d.file_id
ORDER BY grown_gb DESC;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="08_bigfile_tablespaces.sql",
            category="04_Tablespaces_Datafiles",
            purpose="List bigfile tablespaces and their single datafile",
            difficulty="Basic",
            production_use="YES",
            description="""Bigfile tablespaces have exactly one datafile. RMAN and file ops
differ (you resize the tablespace, not add files).""",
            queries=[
                Query(
                    title="Bigfile tablespaces",
                    what="Filters DBA_TABLESPACES.BIGFILE = YES.",
                    columns="TABLESPACE_NAME, FILE_NAME, SIZE_GB.",
                    interpret="One file per TS. Space issues are resolved with ALTER TABLESPACE ... RESIZE.",
                    problem="Bigfile on a file system with a 16TB file size limit approaching the cap.",
                    action="Plan storage. Do not add a second datafile to a bigfile tablespace — it will fail.",
                    caution="Safe.",
                    privileges="SELECT on DBA_TABLESPACES, DBA_DATA_FILES",
                    sql="""SELECT
       ts.tablespace_name,
       ts.status,
       ts.contents,
       df.file_name,
       ROUND(df.bytes/1024/1024/1024,2) AS size_gb,
       df.autoextensible
FROM   dba_tablespaces ts
JOIN   dba_data_files df ON df.tablespace_name = ts.tablespace_name
WHERE  ts.bigfile = 'YES'
ORDER BY ts.tablespace_name;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="09_temp_tablespace_usage.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Temporary tablespace usage (summary)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Instance-level TEMP usage. Session-level detail is in 14_TEMP.
On RAC, each instance has its own TEMP usage — use GV$ views.""",
            queries=[
                Query(
                    title="TEMP usage by instance",
                    what="Reads GV$TEMP_SPACE_HEADER and GV$TEMP_EXTENT_POOL / DBA_TEMP_FREE_SPACE.",
                    columns="TABLESPACE_NAME, TOTAL_GB, USED_GB, FREE_GB.",
                    interpret="USED high during Gather Stats or a hash join is expected and should drop after the statement.",
                    problem="USED stuck near TOTAL after the statement ended — extents not yet released (they are reusable) or a still-open sort.",
                    action="Find the session in 14_TEMP. Do not shrink TEMP during the incident.",
                    caution="Safe.",
                    privileges="SELECT on DBA_TEMP_FREE_SPACE, GV_$SORT_SEGMENT",
                    sql="""SELECT
       tablespace_name,
       ROUND(tablespace_size/1024/1024/1024,2) AS total_gb,
       ROUND(allocated_space/1024/1024/1024,2) AS allocated_gb,
       ROUND(free_space/1024/1024/1024,2) AS free_gb
FROM   dba_temp_free_space;

SELECT
       inst_id,
       tablespace_name,
       ROUND(total_blocks * 8 / 1024 / 1024, 2) AS total_gb_approx_8k,
       ROUND(used_blocks * 8 / 1024 / 1024, 2) AS used_gb_approx_8k
FROM   gv$sort_segment
ORDER BY inst_id, tablespace_name;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="10_temp_usage_by_session.sql",
            category="04_Tablespaces_Datafiles",
            purpose="TEMP consumption by session (pointer to 14_TEMP)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Who is using TEMP right now. Same pattern as 14_TEMP/02 — kept here
so storage DBAs find it next to tablespace scripts. Prefer 14_TEMP for
sort vs hash detail.""",
            queries=[
                Query(
                    title="Sessions using TEMP",
                    what="Joins GV$TEMPSEG_USAGE to GV$SESSION.",
                    columns="SID, USERNAME, SQL_ID, MB_USED, SEGTYPE.",
                    interpret="SEGTYPE SORT vs HASH vs WORK. Multiple rows per session possible.",
                    problem="One session consuming most of TEMP during business hours.",
                    action="Identify SQL_ID and tune or reschedule. Kill only as last resort — generate command in 06_Sessions.",
                    caution="Safe. GV$TEMPSEG_USAGE can miss some 12c+ PGA-only workareas that have not spilled.",
                    privileges="SELECT on GV_$TEMPSEG_USAGE, GV_$SESSION",
                    sql="""SELECT
       t.inst_id,
       t.sid,
       s.serial#,
       s.username,
       s.program,
       s.module,
       t.sql_id,
       t.segtype,
       ROUND(t.blocks * 8 / 1024, 1) AS mb_used
FROM   gv$tempseg_usage t
JOIN   gv$session s
       ON s.inst_id = t.inst_id AND s.saddr = t.session_addr
ORDER BY t.blocks DESC;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="11_undo_usage.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Undo tablespace usage snapshot (storage view)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Storage-centric undo usage. Transaction-centric analysis is in 13_UNDO.""",
            queries=[
                Query(
                    title="Undo space by extent status",
                    what="Aggregates DBA_UNDO_EXTENTS and file usage.",
                    columns="STATUS, MB, TABLESPACE_NAME.",
                    interpret="EXPIRED is reusable. UNEXPIRED can be reused under space pressure (risking ORA-01555).",
                    problem="Almost no EXPIRED and tablespace 95% used.",
                    action="Add undo space or kill/finish a long transaction (13_UNDO).",
                    caution="Safe.",
                    privileges="SELECT on DBA_UNDO_EXTENTS, DBA_DATA_FILES",
                    sql="""SELECT tablespace_name, status,
       ROUND(SUM(bytes)/1024/1024,1) AS mb,
       COUNT(*) AS extents
FROM   dba_undo_extents
GROUP BY tablespace_name, status
ORDER BY tablespace_name, status;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="12_undo_retention.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Show undo_retention vs tuned retention",
            difficulty="Intermediate",
            production_use="YES",
            description="""TUNED_UNDORETENTION in V$UNDOSTAT is what the instance is actually
achieving. If it is far below undo_retention, space is insufficient.""",
            queries=[
                Query(
                    title="Configured vs tuned undo retention",
                    what="Compares parameter undo_retention to V$UNDOSTAT.TUNED_UNDORETENTION.",
                    columns="UNDO_RETENTION, TUNED_UNDORETENTION, SSOLDERRCNT.",
                    interpret="SSOLDERRCNT > 0 in recent intervals means ORA-01555 occurred.",
                    problem="Tuned retention collapsing during the day while a 3-hour report runs.",
                    action="Increase undo datafile size before raising undo_retention. See 13_UNDO/07.",
                    caution="Safe.",
                    privileges="SELECT on V_$PARAMETER, V_$UNDOSTAT",
                    sql="""SELECT name, value FROM v$parameter
WHERE  name IN ('undo_retention','undo_tablespace','undo_management');

SELECT
       TO_CHAR(begin_time,'DD-MON HH24:MI') begin_time,
       tuned_undoretention,
       maxquerylen,
       ssolderrcnt,
       nospaceerrcnt,
       undoblks
FROM   v$undostat
WHERE  begin_time > SYSDATE - 1
ORDER BY begin_time DESC;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="13_segment_growth.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Largest recent segment growth using DBA_HIST_SEG_STAT (AWR)",
            difficulty="Advanced",
            production_use="YES",
            description="""Finds objects that allocated the most space recently. Requires
Diagnostics Pack. Without the pack, use 14_largest_segments.sql as a point-in-time view.""",
            extra_header="LICENSING: DBA_HIST_SEG_STAT requires Diagnostics Pack.",
            queries=[
                Query(
                    title="Top segment space allocations in last 7 days",
                    what="Sums SPACE_ALLOCATED_DELTA from DBA_HIST_SEG_STAT.",
                    columns="OWNER, OBJECT_NAME, SPACE_MB, LOGICAL_READS.",
                    interpret="High allocation on an interface or audit table is a purge candidate.",
                    problem="A custom table growing without a retention policy.",
                    action="Confirm with the application owner before truncate/purge. Generated only.",
                    caution="AWR query — keep the window tight.",
                    privileges="SELECT on DBA_HIST_SEG_STAT, DBA_HIST_SNAPSHOT, DBA_OBJECTS",
                    notes="Requires Diagnostics Pack.",
                    sql="""SELECT
       o.owner,
       o.object_name,
       o.object_type,
       ROUND(SUM(s.space_allocated_delta) / 1024 / 1024, 1) AS space_alloc_mb
FROM   dba_hist_seg_stat s
JOIN   dba_hist_snapshot sn
       ON sn.snap_id = s.snap_id AND sn.dbid = s.dbid AND sn.instance_number = s.instance_number
JOIN   dba_objects o
       ON o.object_id = s.obj#
WHERE  sn.begin_interval_time > SYSDATE - 7
GROUP BY o.owner, o.object_name, o.object_type
HAVING SUM(s.space_allocated_delta) > 0
ORDER BY space_alloc_mb DESC
FETCH FIRST 40 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="14_largest_segments.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Top segments by size right now",
            difficulty="Basic",
            production_use="YES",
            description="""Point-in-time largest segments. Use this when you do not have AWR
or you need an immediate answer.""",
            queries=[
                Query(
                    title="Top 50 segments",
                    what="Ranks DBA_SEGMENTS by BYTES.",
                    columns="OWNER, SEGMENT_NAME, SEGMENT_TYPE, SIZE_GB, TABLESPACE_NAME.",
                    interpret="EBS: large FND, WF, GL, and interface tables are common. Compare to last month's ranking.",
                    problem="A new segment in the top 10 that was not there last week.",
                    action="Drill into table vs index. Check purge programs.",
                    caution="Safe. Slight dictionary cost.",
                    privileges="SELECT on DBA_SEGMENTS",
                    ebs="Useful for EBS",
                    sql="""SELECT
       owner,
       segment_name,
       partition_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb
FROM   dba_segments
ORDER BY bytes DESC
FETCH FIRST 50 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="15_largest_tables.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Largest tables (excludes indexes and undo)",
            difficulty="Basic",
            production_use="YES",
            description="""TABLE and TABLE PARTITION segments only. Pair with 16 for indexes.""",
            queries=[
                Query(
                    title="Top 40 tables",
                    what="Filters DBA_SEGMENTS to TABLE%.",
                    columns="OWNER, SEGMENT_NAME, SIZE_GB, TABLESPACE_NAME.",
                    interpret="Compare table size to corresponding index size — indexes larger than the table can be a design smell or bitmap/function indexes.",
                    problem="Interface table in the top 10.",
                    action="Archive/purge with functional approval.",
                    caution="Safe.",
                    privileges="SELECT on DBA_SEGMENTS",
                    sql="""SELECT
       owner,
       segment_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb
FROM   dba_segments
WHERE  segment_type LIKE 'TABLE%'
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="16_largest_indexes.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Largest indexes",
            difficulty="Basic",
            production_use="YES",
            description="""Index segments that dominate space or cause rebuild windows to be long.""",
            queries=[
                Query(
                    title="Top 40 indexes",
                    what="Filters DBA_SEGMENTS to INDEX%.",
                    columns="OWNER, SEGMENT_NAME, SIZE_GB.",
                    interpret="A bloated index after a mass delete may be a rebuild candidate — rebuild is a change and locks (online rebuild still has constraints).",
                    problem="Index larger than its table after heavy deletes.",
                    action="Confirm with DBA_INDEXES and clustering factor. Rebuild only with a plan.",
                    caution="Safe to query. ALTER INDEX REBUILD is not generated as auto-run.",
                    privileges="SELECT on DBA_SEGMENTS",
                    sql="""SELECT
       owner,
       segment_name,
       partition_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024/1024,2) AS size_gb
FROM   dba_segments
WHERE  segment_type LIKE 'INDEX%'
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="17_free_space_fragmentation.sql",
            category="04_Tablespaces_Datafiles",
            purpose="Detect free space fragmentation that can block extents",
            difficulty="Advanced",
            production_use="YES",
            description="""Compares number of free extents and largest chunk to tablespace
next-extent characteristics.""",
            queries=[
                Query(
                    title="Fragmentation indicators",
                    what="Free chunk histogram per tablespace.",
                    columns="CHUNKS, AVG_CHUNK_MB, MAX_CHUNK_MB.",
                    interpret="LMT AUTOALLOCATE rarely needs coalesce. Dictionary-managed or huge UNIFORM sizes do.",
                    problem="UNIFORM 256MB and max free chunk 128MB — next extent fails.",
                    action="Add a datafile. Avoid exporting/importing just to defragment LMT.",
                    caution="Safe.",
                    privileges="SELECT on DBA_FREE_SPACE, DBA_TABLESPACES",
                    sql="""SELECT
       f.tablespace_name,
       t.extent_management,
       t.allocation_type,
       COUNT(*) AS free_chunks,
       ROUND(AVG(f.bytes)/1024/1024,1) AS avg_chunk_mb,
       ROUND(MAX(f.bytes)/1024/1024,1) AS max_chunk_mb,
       ROUND(SUM(f.bytes)/1024/1024/1024,2) AS free_gb
FROM   dba_free_space f
JOIN   dba_tablespaces t ON t.tablespace_name = f.tablespace_name
GROUP BY f.tablespace_name, t.extent_management, t.allocation_type
ORDER BY free_chunks DESC;""",
                )
            ],
        ),
        Script(
            folder="04_Tablespaces_Datafiles",
            file_name="18_asm_diskgroup_usage.sql",
            category="04_Tablespaces_Datafiles",
            purpose="ASM diskgroup free space from the RDBMS instance",
            difficulty="Intermediate",
            production_use="YES",
            description="""V$ASM_DISKGROUP is visible from the database instance when ASM is used.
Full diskgroup analysis is in folder 16_ASM. Alert bands 70/85/95.""",
            extra_header="Requires ASM. Returns no rows on file-system storage.",
            queries=[
                Query(
                    title="Diskgroup usage from the database",
                    what="Reads V$ASM_DISKGROUP.",
                    columns="NAME, TOTAL_GB, USABLE_FILE_GB, PCT_USED, STATE.",
                    interpret="USABLE_FILE_MB accounts for redundancy. Use that, not raw TOTAL-FREE, for EXTERNAL vs NORMAL.",
                    problem="PCT_USED > 85 on the diskgroup that holds data or FRA.",
                    action="Add disks or move files. See 16_ASM. Do not drop disks during peak.",
                    caution="Safe. STATE CONNECTED from DB instance is normal.",
                    privileges="SELECT on V_$ASM_DISKGROUP",
                    notes="ASM where applicable.",
                    sql="""SELECT
       name,
       state,
       type,
       ROUND(total_mb/1024,2) AS total_gb,
       ROUND(free_mb/1024,2) AS free_gb,
       ROUND(usable_file_mb/1024,2) AS usable_file_gb,
       ROUND((1 - (usable_file_mb/NULLIF(total_mb,0))) * 100,1) AS used_pct_approx,
       CASE
         WHEN (1 - (usable_file_mb/NULLIF(total_mb,0))) * 100 > 95 THEN 'CRITICAL'
         WHEN (1 - (usable_file_mb/NULLIF(total_mb,0))) * 100 > 85 THEN 'WARNING'
         WHEN (1 - (usable_file_mb/NULLIF(total_mb,0))) * 100 > 70 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   v$asm_diskgroup
ORDER BY name;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
