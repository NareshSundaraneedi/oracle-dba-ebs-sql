#!/usr/bin/env python3
from _writer import Query, Script, write_many


def scripts():
    return [
        Script(
            folder="05_Objects",
            file_name="01_invalid_objects.sql",
            category="05_Objects",
            purpose="Invalid objects with dependency hints",
            difficulty="Intermediate",
            production_use="YES",
            description="""Deeper than 01_Basic/28: includes last DDL and a generated compile
command. Compiling is a change and can lock objects.""",
            queries=[
                Query(
                    title="Invalid objects and compile command",
                    what="Lists INVALID objects and generates ALTER ... COMPILE.",
                    columns="OWNER, OBJECT_TYPE, OBJECT_NAME, LAST_DDL_TIME.",
                    interpret="Invalid SYNONYM often means the target is missing after a clone.",
                    problem="Invalid APPS packages after a patch. Invalid SYS after datapatch failure.",
                    action="Use utlrp.sql as SYS for catalog. For EBS use adop/adadmin compile. Generated ALTER is for non-SYS custom objects only after approval.",
                    caution="WARNING: COMPILE locks the object and dependents. Generated only. Never compile SYS/SYSTEM ad hoc.",
                    privileges="SELECT on DBA_OBJECTS",
                    ebs="Useful for EBS",
                    sql="""SELECT owner, object_type, COUNT(*) invalids
FROM   dba_objects
WHERE  status = 'INVALID'
GROUP BY owner, object_type
ORDER BY invalids DESC;

SELECT
       owner,
       object_type,
       object_name,
       last_ddl_time
FROM   dba_objects
WHERE  status = 'INVALID'
ORDER BY owner, object_type, object_name;

-- WARNING: Review carefully. Do not compile SYS/SYSTEM.
SELECT
       CASE object_type
         WHEN 'PACKAGE BODY' THEN 'ALTER PACKAGE "'||owner||'"."'||object_name||'" COMPILE BODY;'
         WHEN 'PACKAGE'      THEN 'ALTER PACKAGE "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'PROCEDURE'    THEN 'ALTER PROCEDURE "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'FUNCTION'     THEN 'ALTER FUNCTION "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'VIEW'         THEN 'ALTER VIEW "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'TRIGGER'      THEN 'ALTER TRIGGER "'||owner||'"."'||object_name||'" COMPILE;'
         WHEN 'SYNONYM'      THEN 'ALTER SYNONYM "'||owner||'"."'||object_name||'" COMPILE;'
         ELSE '-- skip '||object_type||' '||owner||'.'||object_name
       END AS compile_cmd
FROM   dba_objects
WHERE  status = 'INVALID'
AND    owner NOT IN ('SYS','SYSTEM','XDB');""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="02_objects_by_owner.sql",
            category="05_Objects",
            purpose="Object inventory for one owner",
            difficulty="Basic",
            production_use="YES",
            description="""Filtered inventory. Use for custom XX schemas or a product schema
after a patch.""",
            queries=[
                Query(
                    title="Objects for one owner",
                    what="Lists DBA_OBJECTS for &owner_p.",
                    columns="OBJECT_TYPE, OBJECT_NAME, STATUS, LAST_DDL_TIME.",
                    interpret="LAST_DDL_TIME clustering after a patch is expected.",
                    problem="Unexpected tables in APPS (should be synonyms).",
                    action="Investigate object origin. Do not drop.",
                    caution="Safe. Result can be large — filter.",
                    privileges="SELECT on DBA_OBJECTS",
                    sql="""DEFINE owner_p = XXCUST

SELECT object_type, COUNT(*) cnt
FROM   dba_objects
WHERE  owner = '&owner_p'
GROUP BY object_type
ORDER BY cnt DESC;

SELECT object_type, object_name, status, created, last_ddl_time
FROM   dba_objects
WHERE  owner = '&owner_p'
ORDER BY object_type, object_name;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="03_object_counts.sql",
            category="05_Objects",
            purpose="Database-wide object counts excluding Oracle-maintained schemas",
            difficulty="Basic",
            production_use="YES",
            description="""Quick shape of the database for clone vs production comparison.""",
            queries=[
                Query(
                    title="Counts by owner and type",
                    what="Aggregates DBA_OBJECTS excluding oracle_maintained users.",
                    columns="OWNER, OBJECT_TYPE, CNT.",
                    interpret="Compare to a saved baseline after refresh.",
                    problem="Object counts far below production after an incomplete clone.",
                    action="Re-run the clone export/import for missing schemas.",
                    caution="Safe.",
                    privileges="SELECT on DBA_OBJECTS, DBA_USERS",
                    sql="""SELECT o.owner, o.object_type, COUNT(*) cnt
FROM   dba_objects o
JOIN   dba_users u ON u.username = o.owner
WHERE  u.oracle_maintained = 'N'
GROUP BY o.owner, o.object_type
ORDER BY o.owner, o.object_type;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="04_tables_without_indexes.sql",
            category="05_Objects",
            purpose="Find sizable tables that have no indexes at all",
            difficulty="Intermediate",
            production_use="YES",
            description="""A table with no index is not always a problem (small setup tables,
interface staging). Large heap tables with no index often cause
full scans in EBS customizations.""",
            queries=[
                Query(
                    title="Unindexed tables above a size threshold",
                    what="Anti-join DBA_TABLES to DBA_INDEXES and join size from DBA_SEGMENTS.",
                    columns="OWNER, TABLE_NAME, NUM_ROWS, SIZE_MB.",
                    interpret="NUM_ROWS stale if stats are old — check 07_Performance_Tuning stale stats.",
                    problem="Custom XX table > 1GB with zero indexes and frequent queries.",
                    action="Propose an index based on SQL, do not create blindly.",
                    caution="Safe. Creating indexes is a change and is not done here.",
                    privileges="SELECT on DBA_TABLES, DBA_INDEXES, DBA_SEGMENTS",
                    sql="""SELECT
       t.owner,
       t.table_name,
       t.num_rows,
       t.last_analyzed,
       ROUND(s.bytes/1024/1024,1) AS size_mb
FROM   dba_tables t
JOIN   dba_segments s
       ON s.owner = t.owner AND s.segment_name = t.table_name AND s.segment_type LIKE 'TABLE%'
WHERE  t.temporary = 'N'
AND    t.secondary = 'N'
AND    t.nested    = 'NO'
AND    NOT EXISTS (
         SELECT 1 FROM dba_indexes i
         WHERE  i.table_owner = t.owner
         AND    i.table_name  = t.table_name
       )
AND    t.owner NOT IN ('SYS','SYSTEM','XDB')
AND    s.bytes > 64*1024*1024
ORDER BY s.bytes DESC;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="05_unusable_indexes.sql",
            category="05_Objects",
            purpose="List UNUSABLE indexes and partitions",
            difficulty="Intermediate",
            production_use="YES",
            description="""UNUSABLE indexes appear after partition maintenance, failed rebuilds,
or SKIP_UNUSABLE_INDEXES workloads. Queries may error or skip the index.""",
            queries=[
                Query(
                    title="Unusable indexes",
                    what="Reads DBA_INDEXES and DBA_IND_PARTITIONS for STATUS UNUSABLE.",
                    columns="OWNER, INDEX_NAME, STATUS, PARTITION_NAME.",
                    interpret="A global index UNUSABLE after DROP PARTITION is expected until rebuilt.",
                    problem="Unique constraint index UNUSABLE — DML will fail.",
                    action="ALTER INDEX REBUILD is a change. Generated only. Use ONLINE if available and approved.",
                    caution="WARNING: REBUILD generated only. Rebuilds generate redo and can be long.",
                    privileges="SELECT on DBA_INDEXES, DBA_IND_PARTITIONS",
                    sql="""SELECT owner, index_name, table_name, status, tablespace_name
FROM   dba_indexes
WHERE  status = 'UNUSABLE'
ORDER BY owner, index_name;

SELECT index_owner, index_name, partition_name, status
FROM   dba_ind_partitions
WHERE  status = 'UNUSABLE'
ORDER BY index_owner, index_name, partition_name;

-- WARNING: Review carefully before executing.
SELECT 'ALTER INDEX "'||owner||'"."'||index_name||'" REBUILD;' AS rebuild_cmd
FROM   dba_indexes
WHERE  status = 'UNUSABLE'
AND    partitioned = 'NO';""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="06_disabled_constraints.sql",
            category="05_Objects",
            purpose="List disabled constraints",
            difficulty="Intermediate",
            production_use="YES",
            description="""Disabled PK/UK/FK after a data load that never re-enabled them is
a data-integrity incident.""",
            queries=[
                Query(
                    title="Disabled constraints",
                    what="Reads DBA_CONSTRAINTS where STATUS = DISABLED.",
                    columns="OWNER, CONSTRAINT_NAME, CONSTRAINT_TYPE, TABLE_NAME, STATUS.",
                    interpret="TYPE P/U/R/C. NOVAlIDATE enabled is different (not listed here).",
                    problem="Disabled PK on a transactional table.",
                    action="ENABLE is a change and will validate data. Generated only.",
                    caution="WARNING: ENABLE can fail on bad data and locks the table. Generated only.",
                    privileges="SELECT on DBA_CONSTRAINTS",
                    sql="""SELECT owner, constraint_name, constraint_type, table_name, status, validated, last_change
FROM   dba_constraints
WHERE  status = 'DISABLED'
AND    owner NOT IN ('SYS','SYSTEM')
ORDER BY owner, table_name;

-- WARNING: Review carefully. May fail if child/parent data is inconsistent.
SELECT 'ALTER TABLE "'||owner||'"."'||table_name||'" ENABLE CONSTRAINT "'||constraint_name||'";' AS enable_cmd
FROM   dba_constraints
WHERE  status = 'DISABLED'
AND    owner NOT IN ('SYS','SYSTEM');""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="07_foreign_keys.sql",
            category="05_Objects",
            purpose="Find foreign keys without supporting indexes (parent update / child delete risk)",
            difficulty="Advanced",
            production_use="YES",
            description="""Unindexed FKs cause TM lock waits (enq: TM - contention) when the
parent is updated/deleted. Classic EBS customization issue.""",
            queries=[
                Query(
                    title="FK columns missing a leading index",
                    what="Compares DBA_CONS_COLUMNS of referential constraints to DBA_IND_COLUMNS.",
                    columns="OWNER, TABLE_NAME, CONSTRAINT_NAME, COLUMNS.",
                    interpret="An index that starts with the FK columns is sufficient. This query flags FKs with no such index.",
                    problem="enq: TM - contention on the child table during parent deletes.",
                    action="Create an index on the FK columns after reviewing cardinality. Change request required.",
                    caution="Safe to query. Index create is a change.",
                    privileges="SELECT on DBA_CONSTRAINTS, DBA_CONS_COLUMNS, DBA_IND_COLUMNS",
                    sql="""SELECT
       c.owner,
       c.table_name,
       c.constraint_name,
       LISTAGG(cc.column_name, ',') WITHIN GROUP (ORDER BY cc.position) AS fk_cols
FROM   dba_constraints c
JOIN   dba_cons_columns cc
       ON cc.owner = c.owner AND cc.constraint_name = c.constraint_name
WHERE  c.constraint_type = 'R'
AND    c.owner NOT IN ('SYS','SYSTEM')
AND    NOT EXISTS (
         SELECT 1
         FROM   dba_ind_columns ic
         WHERE  ic.table_owner = c.owner
         AND    ic.table_name  = c.table_name
         AND    ic.column_position = 1
         AND    ic.column_name = (
                  SELECT column_name FROM dba_cons_columns
                  WHERE  owner = c.owner AND constraint_name = c.constraint_name AND position = 1
                )
       )
GROUP BY c.owner, c.table_name, c.constraint_name
ORDER BY c.owner, c.table_name;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="08_triggers.sql",
            category="05_Objects",
            purpose="List enabled triggers (performance and mutating-table suspects)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Row-level triggers on busy EBS tables are a common source of
unexpected CPU and waits. Inventory first, then inspect code.""",
            queries=[
                Query(
                    title="Non-system triggers",
                    what="Reads DBA_TRIGGERS excluding SYS.",
                    columns="OWNER, TRIGGER_NAME, TABLE_NAME, STATUS, TRIGGERING_EVENT.",
                    interpret="ENABLED AFTER ROW on a high-DML table is a performance suspect.",
                    problem="A custom trigger introduced last night on GL_JE_LINES.",
                    action="Review trigger body. Disable only with application approval — generated only.",
                    caution="WARNING: DISABLE generated only.",
                    privileges="SELECT on DBA_TRIGGERS",
                    ebs="Useful for EBS",
                    sql="""SELECT
       owner,
       trigger_name,
       table_owner,
       table_name,
       triggering_event,
       trigger_type,
       status
FROM   dba_triggers
WHERE  owner NOT IN ('SYS','SYSTEM','XDB')
ORDER BY table_owner, table_name, trigger_name;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="09_synonyms.sql",
            category="05_Objects",
            purpose="Find invalid or cross-schema synonyms",
            difficulty="Intermediate",
            production_use="YES",
            description="""APPS is mostly synonyms. Invalid synonyms after a clone usually mean
the target schema was not imported.""",
            queries=[
                Query(
                    title="Invalid synonyms and missing targets",
                    what="Joins DBA_SYNONYMS to DBA_OBJECTS.",
                    columns="OWNER, SYNONYM_NAME, TABLE_OWNER, TABLE_NAME.",
                    interpret="Missing target object = broken synonym.",
                    problem="Thousands of invalid APPS synonyms after a partial import.",
                    action="Import the missing product schema. Do not recreate synonyms by hand at scale.",
                    caution="Safe. Full APPS synonym list is huge — this query lists broken ones.",
                    privileges="SELECT on DBA_SYNONYMS, DBA_OBJECTS",
                    ebs="Critical for EBS",
                    sql="""SELECT
       s.owner,
       s.synonym_name,
       s.table_owner,
       s.table_name,
       s.db_link
FROM   dba_synonyms s
WHERE  s.db_link IS NULL
AND    NOT EXISTS (
         SELECT 1 FROM dba_objects o
         WHERE  o.owner = s.table_owner
         AND    o.object_name = s.table_name
       )
AND    s.owner NOT IN ('PUBLIC')
AND    ROWNUM <= 500
ORDER BY s.owner, s.synonym_name;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="10_views.sql",
            category="05_Objects",
            purpose="List invalid views and view dependency counts",
            difficulty="Intermediate",
            production_use="YES",
            description="""Invalid views break APIs and concurrent programs that query them.""",
            queries=[
                Query(
                    title="Invalid views",
                    what="Filters DBA_OBJECTS / DBA_VIEWS for INVALID.",
                    columns="OWNER, VIEW_NAME, TEXT_LENGTH.",
                    interpret="TEXT_LENGTH huge views are often generated EBS views — compile via EBS tools.",
                    problem="Custom view INVALID after an underlying table column drop.",
                    action="Compile or recreate from source control.",
                    caution="Safe.",
                    privileges="SELECT on DBA_VIEWS, DBA_OBJECTS",
                    sql="""SELECT o.owner, o.object_name, o.last_ddl_time, v.text_length
FROM   dba_objects o
JOIN   dba_views v ON v.owner = o.owner AND v.view_name = o.object_name
WHERE  o.object_type = 'VIEW'
AND    o.status = 'INVALID'
ORDER BY o.owner, o.object_name;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="11_sequences.sql",
            category="05_Objects",
            purpose="Sequences near MAXVALUE or with odd cache settings",
            difficulty="Intermediate",
            production_use="YES",
            description="""Sequence exhaustion raises ORA-08004. RAC hot sequences with
NOCACHE cause SQ enqueue contention.""",
            queries=[
                Query(
                    title="Sequence headroom and cache",
                    what="Reads DBA_SEQUENCES for remaining values and cache.",
                    columns="SEQUENCE_NAME, LAST_NUMBER, MAX_VALUE, CACHE_SIZE, ORDER_FLAG.",
                    interpret="CYCLE YES wraps. ORDER YES on RAC is a scalability tax.",
                    problem="LAST_NUMBER within 10% of MAXVALUE. CACHE_SIZE 0 on a high-rate sequence.",
                    action="ALTER SEQUENCE ... MAXVALUE / CACHE — generated only.",
                    caution="WARNING: Changing sequences can create gaps or key collisions if mishandled. Generated only.",
                    privileges="SELECT on DBA_SEQUENCES",
                    sql="""SELECT
       sequence_owner,
       sequence_name,
       last_number,
       min_value,
       max_value,
       increment_by,
       cache_size,
       cycle_flag,
       order_flag,
       ROUND(last_number * 100 / NULLIF(max_value,0), 6) AS pct_used
FROM   dba_sequences
WHERE  sequence_owner NOT IN ('SYS','SYSTEM')
AND    (
         cache_size = 0
         OR last_number > max_value * 0.8
       )
ORDER BY pct_used DESC NULLS LAST;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="12_materialized_views.sql",
            category="05_Objects",
            purpose="MV freshness, compile state, and last refresh",
            difficulty="Intermediate",
            production_use="YES",
            description="""Stale MVs cause wrong results in reporting. Refresh-on-commit MVs
can destroy OLTP performance.""",
            queries=[
                Query(
                    title="Materialized views",
                    what="Reads DBA_MVIEWS.",
                    columns="OWNER, MVIEW_NAME, STALENESS, LAST_REFRESH_DATE, REFRESH_MODE.",
                    interpret="STALENESS NEEDS_COMPILE or UNUSABLE is a break. FRESH is good.",
                    problem="REFRESH_MODE COMMIT on a heavy OLTP table.",
                    action="Change refresh strategy with the application team. Do not refresh ad hoc during peak unless agreed.",
                    caution="Safe to query. DBMS_MVIEW.REFRESH is a change/load.",
                    privileges="SELECT on DBA_MVIEWS",
                    sql="""SELECT
       owner,
       mview_name,
       compile_state,
       staleness,
       refresh_mode,
       refresh_method,
       last_refresh_date,
       last_refresh_type
FROM   dba_mviews
ORDER BY owner, mview_name;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="13_dependencies.sql",
            category="05_Objects",
            purpose="Show dependencies for one object",
            difficulty="Intermediate",
            production_use="YES",
            description="""Used before dropping or altering a custom object.""",
            queries=[
                Query(
                    title="Dependencies of one object",
                    what="Reads DBA_DEPENDENCIES in both directions.",
                    columns="NAME, TYPE, REFERENCED_NAME, REFERENCED_TYPE.",
                    interpret="Hard dependencies must be recompiled after a change.",
                    problem="A custom view depended on by many concurrent programs.",
                    action="Impact-assess before DDL.",
                    caution="Safe.",
                    privileges="SELECT on DBA_DEPENDENCIES",
                    sql="""DEFINE owner_p = XXCUST
DEFINE name_p  = XX_CUSTOM_PKG

SELECT owner, name, type, referenced_owner, referenced_name, referenced_type, referenced_link_name, dependency_type
FROM   dba_dependencies
WHERE  owner = '&owner_p' AND name = '&name_p'
ORDER BY referenced_owner, referenced_name;

SELECT owner, name, type, referenced_owner, referenced_name, referenced_type
FROM   dba_dependencies
WHERE  referenced_owner = '&owner_p' AND referenced_name = '&name_p'
ORDER BY owner, name;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="14_object_modifications.sql",
            category="05_Objects",
            purpose="Objects with recent LAST_DDL_TIME",
            difficulty="Intermediate",
            production_use="YES",
            description="""Finds what changed recently — useful after an unexplained break.""",
            queries=[
                Query(
                    title="DDL in the last 7 days (non-Oracle schemas)",
                    what="Filters DBA_OBJECTS by LAST_DDL_TIME.",
                    columns="OWNER, OBJECT_NAME, OBJECT_TYPE, LAST_DDL_TIME.",
                    interpret="Compile-only DDL still updates LAST_DDL_TIME.",
                    problem="A production package changed with no ticket.",
                    action="Diff against source control / EBS patch history.",
                    caution="Safe. EBS patching will produce a large result — tighten the window.",
                    privileges="SELECT on DBA_OBJECTS, DBA_USERS",
                    sql="""SELECT o.owner, o.object_type, o.object_name, o.last_ddl_time, o.status
FROM   dba_objects o
JOIN   dba_users u ON u.username = o.owner
WHERE  u.oracle_maintained = 'N'
AND    o.last_ddl_time > SYSDATE - 7
ORDER BY o.last_ddl_time DESC;""",
                )
            ],
        ),
        Script(
            folder="05_Objects",
            file_name="15_compile_invalid_objects.sql",
            category="05_Objects",
            purpose="Guided compile approach (utlrp / DBMS_UTILITY) without auto-executing",
            difficulty="Advanced",
            production_use="YES",
            description="""Explains the safe compile path. The script only generates calls.
SYS.UTLRP is the supported catalog compile.""",
            queries=[
                Query(
                    title="Generated compile helpers",
                    what="Prints recommended compile methods; does not execute utlrp.",
                    columns="GUIDANCE.",
                    interpret="Use utlrp.sql connected as SYS after patches. For a single custom package, use ALTER PACKAGE COMPILE.",
                    problem="Looping compiles that never go valid — missing privilege or missing object.",
                    action="Fix the first error in DBA_ERRORS, do not blindly loop.",
                    caution="WARNING: Do not run utlrp during peak on a busy OLTP system without a window.",
                    privileges="SELECT on DBA_ERRORS, DBA_OBJECTS",
                    sql="""SELECT owner, name, type, line, position, text
FROM   dba_errors
WHERE  owner NOT IN ('SYS','SYSTEM')
ORDER BY owner, name, sequence;

PROMPT Recommended (run manually as SYS after a patch window):
PROMPT   @$ORACLE_HOME/rdbms/admin/utlrp.sql
PROMPT
PROMPT For EBS application objects prefer:
PROMPT   adop phase=apply (compile) or adadmin compile apps schema
PROMPT
-- WARNING: Review carefully. Example only, not executed.
-- EXEC DBMS_UTILITY.COMPILE_SCHEMA('XXCUST', FALSE);""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
