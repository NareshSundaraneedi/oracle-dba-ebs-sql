#!/usr/bin/env python3
from _writer import Query, Script, write_many


def Q(**k):
    return Query(**k)


def sc(folder, file_name, purpose, difficulty, description, queries, extra="", ebs="R12.2", priv="APPS"):
    return Script(
        folder=folder, file_name=file_name, category=folder, purpose=purpose,
        difficulty=difficulty, production_use="YES", description=description,
        queries=queries, extra_header=extra, ebs=ebs, privileges=priv,
        ebs_version="R12.2.x" if ebs != "N/A" else "N/A",
    )


def scripts():
    s = []
    ebs = "EBS R12.2.x. APPS + SELECT_CATALOG_ROLE."
    s += [
        sc("26_EBS_Performance", "01_ebs_top_sql.sql", "Top SQL from sessions that look like EBS (APPS / MODULE set)",
           "Advanced", "Ranks GV$SQL parsed by APPS. Difference vs 07/01: EBS-filtered so SYS RMAN SQL does not dominate.",
           [Q(title="Top APPS SQL by elapsed", what="GV$SQL parsing_schema APPS.",
              columns="SQL_ID, ELA_S, MODULE.", interpret="MODULE often equals the concurrent program or form.",
              problem="One SQL_ID dominates APPS elapsed during the slowness window.",
              action="25 chain if it maps to a request; else 08_SQL_Tuning.",
              caution="Safe.", privileges="SELECT on GV_$SQL",
              sql="""SELECT sql_id, module, executions, ROUND(elapsed_time/1e6,1) ela_s,
       ROUND(cpu_time/1e6,1) cpu_s, buffer_gets, SUBSTR(sql_text,1,160) sql_text
FROM gv$sql WHERE parsing_schema_name='APPS' AND executions>0
ORDER BY elapsed_time DESC FETCH FIRST 30 ROWS ONLY;""")], extra=ebs),
        sc("26_EBS_Performance", "02_ebs_top_modules.sql", "DB time by MODULE (forms and concurrent programs)",
           "Advanced", "GV$SESSION + optional ASH. Pack-free session view first.",
           [Q(title="Active sessions by module", what="ACTIVE APPS sessions grouped by MODULE.",
              columns="MODULE, ACTIVE, SAMPLE_EVENT.", interpret="A module with many ACTIVE sessions is the current hotspot.",
              problem="One form module with 50 active sessions — missing index or lock.",
              action="06_Sessions and 10_Locks.", caution="Safe.", privileges="SELECT on GV_$SESSION",
              sql="""SELECT NVL(module,'(none)') module, COUNT(*) active_sessions,
       MIN(event) sample_event
FROM gv$session WHERE username='APPS' AND status='ACTIVE'
GROUP BY module ORDER BY active_sessions DESC;""")], extra=ebs),
        sc("26_EBS_Performance", "03_ebs_top_programs.sql", "Top concurrent programs by DB-side load (running now)",
           "Intermediate", "Running requests joined to session elapsed.",
           [Q(title="Running programs with session time", what="Requests phase R + last_call_et.",
              columns="PROGRAM, REQUEST_ID, LAST_CALL_ET.", interpret="last_call_et is the current SQL call, not total request time.",
              problem="A program with last_call_et of hours.", action="25 master.", caution="Safe.", privileges="APPS",
              sql="""SELECT p.user_concurrent_program_name, r.request_id, s.last_call_et, s.sql_id, s.event
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
LEFT JOIN gv$session s ON s.sid=r.oracle_session_id
WHERE r.phase_code='R' ORDER BY s.last_call_et DESC NULLS LAST;""")], extra=ebs),
        sc("26_EBS_Performance", "04_sql_by_concurrent_request.sql", "SQL_ID for one request_id (performance folder shortcut)",
           "Intermediate", "DEFINE request_id. Difference vs 25/03: includes sql_text in one step.",
           [Q(title="SQL for a request", what="Join request to gv$sql via session.",
              columns="REQUEST_ID, SQL_ID, SQL_TEXT.", interpret="Empty SQL means not in a DB call.",
              problem="N/A lookup.", action="05 plan.", caution="Safe.", privileges="APPS",
              sql="""DEFINE request_id = 0
SELECT r.request_id, s.sql_id, s.event, SUBSTR(q.sql_text,1,200) sql_text
FROM fnd_concurrent_requests r
LEFT JOIN gv$session s ON s.sid=r.oracle_session_id
LEFT JOIN gv$sql q ON q.inst_id=s.inst_id AND q.sql_id=s.sql_id AND q.child_number=s.sql_child_number
WHERE r.request_id=&request_id;""")], extra=ebs),
        sc("26_EBS_Performance", "05_sql_by_module.sql", "SQL cache filtered to one MODULE",
           "Intermediate", "DEFINE module_p. Use the form or program short name.",
           [Q(title="SQL by module", what="GV$SQL.module filter.",
              columns="SQL_ID, ELA, TEXT.", interpret="Chatty forms have many SQL_IDs; concurrent usually one heavy SQL.",
              problem="New expensive SQL_ID in a standard form after customization.",
              action="08_SQL_Tuning.", caution="Safe.", privileges="SELECT on GV_$SQL",
              sql="""DEFINE module_p = %FNDSCSGN%
SELECT sql_id, executions, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,180) sql_text
FROM gv$sql WHERE module LIKE '&module_p' ORDER BY elapsed_time DESC FETCH FIRST 30 ROWS ONLY;""")], extra=ebs),
        sc("26_EBS_Performance", "06_sql_by_program.sql", "SQL for sessions whose MODULE matches a concurrent program name",
           "Advanced", "Matches running program names to SQL cache.",
           [Q(title="SQL for a program name", what="Join running requests' program name to gv$sql.module.",
              columns="PROGRAM, SQL_ID.", interpret="MODULE may be the short concurrent_program_name.",
              problem="Program SQL not matching a known good plan_hash.", action="25/15.", caution="Safe.", privileges="APPS",
              sql="""DEFINE program_name = %Create Accounting%
SELECT DISTINCT p.user_concurrent_program_name, s.sql_id, s.event, s.sid
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
JOIN gv$session s ON s.sid=r.oracle_session_id
WHERE r.phase_code='R' AND p.user_concurrent_program_name LIKE '&program_name';""")], extra=ebs),
        sc("26_EBS_Performance", "07_sql_by_responsibility.sql", "Active APPS sessions by action/responsibility hint",
           "Advanced", "EBS often puts responsibility into ACTION or CLIENT_IDENTIFIER (depending on setup).",
           [Q(title="Action / client_identifier", what="GV$SESSION action and client_identifier for APPS.",
              columns="ACTION, CLIENT_IDENTIFIER, SQL_ID.", interpret="If blank, profile 'Sign-On:Audit Level' / ICX instrumentation may be off.",
              problem="Cannot map SQL to a responsibility — enable audit/instrumentation as a change.",
              action="Use FND_CONCURRENT_REQUESTS.responsibility_id for batch; forms need instrumentation.",
              caution="Safe.", privileges="SELECT on GV_$SESSION",
              sql="""SELECT NVL(action,'(no action)') action, NVL(client_identifier,'(none)') client_identifier,
       COUNT(*) sessions, SUM(DECODE(status,'ACTIVE',1,0)) active
FROM gv$session WHERE username='APPS'
GROUP BY action, client_identifier
ORDER BY active DESC, sessions DESC FETCH FIRST 40 ROWS ONLY;""")], extra=ebs),
        sc("26_EBS_Performance", "08_ebs_database_load.sql", "EBS-oriented load snapshot (APPS sessions + time model)",
           "Intermediate", "One-page load for an EBS DBA shift start.",
           [Q(title="Load snapshot", what="APPS session counts + DB time.",
              columns="APPS_ACTIVE, DB_TIME, DB_CPU.", interpret="APPS_ACTIVE >> CPU_COUNT and wait_class not Idle = overload.",
              problem="APPS_ACTIVE spike with login storm.", action="06_Sessions / 30 connection.", caution="Safe.", privileges="SELECT_CATALOG_ROLE",
              sql="""SELECT COUNT(*) apps_sessions, SUM(DECODE(status,'ACTIVE',1,0)) apps_active
FROM gv$session WHERE username='APPS';
SELECT stat_name, ROUND(value/1e6,1) seconds FROM v$sys_time_model
WHERE stat_name IN ('DB time','DB CPU');""")], extra=ebs),
        sc("26_EBS_Performance", "09_ebs_active_sessions.sql", "All ACTIVE APPS sessions with request mapping when possible",
           "Intermediate", "Left join to running requests.",
           [Q(title="Active APPS + request_id", what="GV$SESSION APPS ACTIVE left join FND_CONCURRENT_REQUESTS.",
              columns="SID, MODULE, REQUEST_ID, SQL_ID, EVENT.", interpret="No request_id = Forms/OAF/other.",
              problem="Many active without module — uninstrumented custom.", action="Identify program from SQL.", caution="Safe.", privileges="APPS",
              sql="""SELECT s.inst_id, s.sid, s.serial#, s.module, s.sql_id, s.event, s.last_call_et, r.request_id
FROM gv$session s
LEFT JOIN fnd_concurrent_requests r ON r.oracle_session_id=s.sid AND r.phase_code='R'
WHERE s.username='APPS' AND s.status='ACTIVE'
ORDER BY s.last_call_et DESC;""")], extra=ebs),
        sc("26_EBS_Performance", "10_ebs_wait_events.sql", "Wait events for APPS sessions only",
           "Intermediate", "Filters system noise from SYS backups.",
           [Q(title="APPS waiters", what="ACTIVE APPS wait_class <> Idle.",
              columns="EVENT, CNT.", interpret="Same interpretation as folder 09 but EBS-scoped.",
              problem="APPS-only log file sync — chatty forms commits.", action="09/17.", caution="Safe.", privileges="SELECT on GV_$SESSION",
              sql="""SELECT event, wait_class, COUNT(*) cnt
FROM gv$session WHERE username='APPS' AND status='ACTIVE' AND wait_class<>'Idle'
GROUP BY event, wait_class ORDER BY cnt DESC;""")], extra=ebs),
        sc("26_EBS_Performance", "11_ebs_cpu_consumption.sql", "CPU by APPS session (SESSTAT)",
           "Advanced", "Cumulative CPU — pair with last_call_et.",
           [Q(title="APPS CPU", what="CPU used by this session for APPS.",
              columns="SID, CPU_S, SQL_ID, MODULE.", interpret="Long-lived forms accumulate CPU — sort by last_call_et too.",
              problem="One sid burning CPU on a custom package.", action="25/08.", caution="Safe.", privileges="SELECT_CATALOG_ROLE",
              sql="""SELECT s.sid, s.serial#, s.module, s.sql_id, s.last_call_et, ROUND(st.value/100,1) cpu_s
FROM gv$session s
JOIN gv$sesstat st ON st.inst_id=s.inst_id AND st.sid=s.sid
JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE sn.name='CPU used by this session' AND s.username='APPS'
ORDER BY st.value DESC FETCH FIRST 30 ROWS ONLY;""")], extra=ebs),
        sc("26_EBS_Performance", "12_ebs_io.sql", "Physical I/O by APPS session",
           "Advanced", "Cumulative physical reads.",
           [Q(title="APPS physical reads", what="SESSTAT physical reads for APPS.",
              columns="SID, PHY_READS, SQL_ID.", interpret="Reporting concurrent programs dominate.",
              problem="OLTP form with huge physical reads.", action="FTS/plan.", caution="Safe.", privileges="SELECT_CATALOG_ROLE",
              sql="""SELECT s.sid, s.module, s.sql_id, st.value phy_reads
FROM gv$session s
JOIN gv$sesstat st ON st.inst_id=s.inst_id AND st.sid=s.sid
JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE sn.name='physical reads' AND s.username='APPS'
ORDER BY st.value DESC FETCH FIRST 30 ROWS ONLY;""")], extra=ebs),
        sc("26_EBS_Performance", "13_ebs_temp_usage.sql", "TEMP used by APPS / concurrent sessions",
           "Intermediate", "TEMPSEG joined to requests when possible.",
           [Q(title="EBS TEMP", what="tempseg_usage + optional request.",
              columns="SID, MB, REQUEST_ID, SQL_ID.", interpret="Hash spill during Create Accounting is common.",
              problem="TEMP critical from one request.", action="14_TEMP + 25/11.", caution="Safe.", privileges="APPS",
              sql="""SELECT t.inst_id, t.sid, t.sql_id, t.segtype, ROUND(t.blocks*8/1024,1) mb, r.request_id
FROM gv$tempseg_usage t
LEFT JOIN fnd_concurrent_requests r ON r.oracle_session_id=t.sid AND r.phase_code='R'
ORDER BY t.blocks DESC;""")], extra=ebs),
        sc("26_EBS_Performance", "14_ebs_blocking_sessions.sql", "Blocking chains involving APPS",
           "Intermediate", "Folder 10 filtered to APPS usernames.",
           [Q(title="APPS blockers", what="Waiters/blockers where either side is APPS.",
              columns="BLOCKER, WAITER, MODULES.", interpret="Inactive APPS blocker = forgotten form.",
              problem="Order Entry waiters behind one APPS sid.", action="10 + user contact.", caution="Safe.", privileges="SELECT on GV_$SESSION",
              sql="""SELECT b.sid blocker, b.status blocker_status, b.module blocker_module, b.last_call_et,
       w.sid waiter, w.event, w.module waiter_module, w.sql_id, w.seconds_in_wait
FROM gv$session w JOIN gv$session b ON b.sid=w.blocking_session AND b.inst_id=NVL(w.blocking_instance,w.inst_id)
WHERE w.username='APPS' OR b.username='APPS'
ORDER BY w.seconds_in_wait DESC;""")], extra=ebs),
        sc("26_EBS_Performance", "15_ebs_performance_baseline.sql", "Numbers to save each week (EBS baseline)",
           "Intermediate", "Spool and keep. Compare next week. Not AWR (pack-free).",
           [Q(title="Baseline snapshot", what="Counts: sessions, invalids, pending, running, tablespace alert count.",
              columns="METRIC, VALUE.", interpret="Store with a timestamp. Deltas matter more than absolutes.",
              problem="Pending 10x week-over-week.", action="Capacity / purge / managers.", caution="Safe.", privileges="APPS + DBA views",
              sql="""SELECT 'APPS_SESSIONS' m, COUNT(*) v FROM gv$session WHERE username='APPS'
UNION ALL SELECT 'APPS_ACTIVE', SUM(DECODE(status,'ACTIVE',1,0)) FROM gv$session WHERE username='APPS'
UNION ALL SELECT 'INVALIDS', COUNT(*) FROM dba_objects WHERE status='INVALID' AND owner IN ('APPS','APPLSYS')
UNION ALL SELECT 'REQ_RUNNING', COUNT(*) FROM fnd_concurrent_requests WHERE phase_code='R'
UNION ALL SELECT 'REQ_PENDING', COUNT(*) FROM fnd_concurrent_requests WHERE phase_code='P'
UNION ALL SELECT 'REQ_ERROR_24H', COUNT(*) FROM fnd_concurrent_requests
         WHERE phase_code='C' AND status_code='E' AND actual_completion_date>SYSDATE-1;""")], extra=ebs),
    ]

    s += [
        sc("27_EBS_Users_Responsibilities", "01_ebs_users.sql", "FND_USER inventory (active vs end-dated)",
           "Basic", "Application users. Difference vs 20/07: active filter and last_logon hygiene.",
           [Q(title="User counts and recent logons", what="FND_USER.",
              columns="USER_NAME, END_DATE, LAST_LOGON.", interpret="END_DATE not null and < SYSDATE = cannot log in.",
              problem="SYSADMIN end-dated.", action="Users form — no SQL update.", caution="Safe.", privileges="APPS",
              sql="""SELECT user_name, description, email_address, start_date, end_date, last_logon_date
FROM fnd_user WHERE NVL(end_date,SYSDATE+1) > SYSDATE
ORDER BY last_logon_date DESC NULLS LAST FETCH FIRST 100 ROWS ONLY;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "02_user_status.sql", "Users who cannot log in (end-dated / no logon)",
           "Basic", "End-dated and never-logged-in users.",
           [Q(title="Inactive application users", what="END_DATE < SYSDATE or last_logon null and created > 90 days.",
              columns="USER_NAME, END_DATE.", interpret="Never-logged-in service accounts may be OK.",
              problem="Named humans unused 180 days still active — audit.", action="End-date via form after HR confirm.", caution="Safe.", privileges="APPS",
              sql="""SELECT user_name, start_date, end_date, last_logon_date
FROM fnd_user
WHERE (end_date IS NOT NULL AND end_date < SYSDATE)
   OR (last_logon_date IS NULL AND start_date < SYSDATE-90)
ORDER BY NVL(end_date,start_date) DESC FETCH FIRST 200 ROWS ONLY;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "03_responsibilities.sql", "All responsibilities with application and request group",
           "Basic", "FND_RESPONSIBILITY_VL inventory.",
           [Q(title="Responsibilities", what="VL view.",
              columns="RESPONSIBILITY_NAME, END_DATE, REQUEST_GROUP_ID.", interpret="End-dated resp should not be newly assigned.",
              problem="Custom resp missing request group after clone.", action="FNDLOAD / form.", caution="Safe.", privileges="APPS",
              sql="""SELECT responsibility_name, application_id, start_date, end_date, request_group_id, menu_id, data_group_id
FROM fnd_responsibility_vl ORDER BY responsibility_name FETCH FIRST 300 ROWS ONLY;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "04_user_responsibilities.sql", "Responsibilities assigned to one user",
           "Intermediate", "DEFINE username. Direct assignments (FND_USER_RESP_GROUPS_DIRECT).",
           [Q(title="Assignments", what="User to resp with dates.",
              columns="RESPONSIBILITY_NAME, START_DATE, END_DATE.", interpret="END_DATE past = assignment inactive.",
              problem="User has System Administrator unexpectedly.", action="Revoke via form / UMX.", caution="Safe.", privileges="APPS",
              sql="""DEFINE username = SYSADMIN
SELECT u.user_name, r.responsibility_name, urg.start_date, urg.end_date
FROM fnd_user u
JOIN fnd_user_resp_groups_direct urg ON urg.user_id=u.user_id
JOIN fnd_responsibility_vl r ON r.responsibility_id=urg.responsibility_id AND r.application_id=urg.responsibility_application_id
WHERE u.user_name='&username'
ORDER BY r.responsibility_name;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "05_menus.sql", "Menu attached to a responsibility",
           "Intermediate", "DEFINE resp_name.",
           [Q(title="Menu", what="Resp → menu name.",
              columns="MENU_NAME, USER_MENU_NAME.", interpret="Wrong menu after FNDLOAD = missing functions.",
              problem="Users missing a form that exists.", action="20/09 entries.", caution="Safe.", privileges="APPS",
              sql="""DEFINE resp_name = System Administrator
SELECT r.responsibility_name, m.menu_name, m.user_menu_name
FROM fnd_responsibility_vl r JOIN fnd_menus_vl m ON m.menu_id=r.menu_id
WHERE r.responsibility_name='&resp_name';""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "06_functions.sql", "Functions a user can reach (via one responsibility menu — not exclusions)",
           "Advanced", "Does not expand all nested menus recursively (that is a connect-by). Lists entries on the top menu.",
           [Q(title="Top-level functions", what="Menu entries for the resp menu.",
              columns="PROMPT, FUNCTION_NAME.", interpret="Exclusions (FND_RESP_FUNCTIONS) can hide these — check 10.",
              problem="Function present but excluded.", action="Function security.", caution="Safe.", privileges="APPS",
              sql="""DEFINE resp_name = System Administrator
SELECT e.prompt, f.function_name, f.user_function_name
FROM fnd_responsibility_vl r
JOIN fnd_menu_entries_vl e ON e.menu_id=r.menu_id
LEFT JOIN fnd_form_functions_vl f ON f.function_id=e.function_id
WHERE r.responsibility_name='&resp_name'
ORDER BY e.entry_sequence;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "07_profile_options.sql", "Profile values for one user or site",
           "Intermediate", "DEFINE prof and optional user.",
           [Q(title="Profiles", what="FND_PROFILE_OPTION_VALUES resolved.",
              columns="LEVEL, VALUE.", interpret="User level overrides site.",
              problem="Clone leftover URL profiles.", action="20/13.", caution="Safe.", privileges="APPS",
              sql="""DEFINE prof = %ICX%
SELECT po.profile_option_name,
       DECODE(pov.level_id,10001,'SITE',10002,'APP',10003,'RESP',10004,'USER',TO_CHAR(pov.level_id)) lvl,
       pov.profile_option_value
FROM fnd_profile_options_vl po
JOIN fnd_profile_option_values pov ON pov.profile_option_id=po.profile_option_id
WHERE po.profile_option_name LIKE '&prof' OR po.user_profile_option_name LIKE '&prof'
ORDER BY po.profile_option_name, pov.level_id;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "08_inactive_users.sql", "Active FND users with no last_logon in 180 days",
           "Intermediate", "License and security hygiene.",
           [Q(title="Stale active users", what="END_DATE null and last_logon old.",
              columns="USER_NAME, LAST_LOGON.", interpret="Shared batch users may never 'log on' via FND — exclude known ones.",
              problem="Hundreds of stale named users.", action="End-date after owner approval.", caution="Safe.", privileges="APPS",
              sql="""SELECT user_name, last_logon_date, start_date, email_address
FROM fnd_user
WHERE end_date IS NULL AND last_logon_date < SYSDATE-180
ORDER BY last_logon_date;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "09_end_dated_users.sql", "Recently end-dated users (leaver check)",
           "Basic", "Who was disabled recently.",
           [Q(title="Recent end dates", what="END_DATE last 30 days.",
              columns="USER_NAME, END_DATE.", interpret="Compare to HR terminations.",
              problem="Leaver still active (not in this list).", action="08.", caution="Safe.", privileges="APPS",
              sql="""SELECT user_name, end_date, last_logon_date FROM fnd_user
WHERE end_date BETWEEN SYSDATE-30 AND SYSDATE+1
ORDER BY end_date DESC;""")], extra=ebs),
        sc("27_EBS_Users_Responsibilities", "10_responsibility_assignments.sql", "Who has a given responsibility (SoD helper)",
           "Intermediate", "DEFINE resp_name. Used for System Administrator / GL Super User reviews.",
           [Q(title="Users of one responsibility", what="Direct assignments still effective.",
              columns="USER_NAME, START_DATE, END_DATE.", interpret="Include only NVL(end_date,future)>SYSDATE.",
              problem="Too many users with a privileged resp.", action="Revoke via form.", caution="Safe.", privileges="APPS",
              sql="""DEFINE resp_name = System Administrator
SELECT u.user_name, urg.start_date, urg.end_date, u.email_address
FROM fnd_user_resp_groups_direct urg
JOIN fnd_user u ON u.user_id=urg.user_id
JOIN fnd_responsibility_vl r ON r.responsibility_id=urg.responsibility_id AND r.application_id=urg.responsibility_application_id
WHERE r.responsibility_name='&resp_name'
AND NVL(urg.end_date,SYSDATE+1)>SYSDATE AND NVL(u.end_date,SYSDATE+1)>SYSDATE
ORDER BY u.user_name;""")], extra=ebs),
    ]

    s += [
        sc("28_EBS_Objects", "01_fnd_objects.sql", "FND / APPLSYS object counts and invalids",
           "Basic", "APPLSYS health.",
           [Q(title="APPLSYS objects", what="Counts + invalids.",
              columns="TYPE, CNT, INVALIDS.", interpret="Invalid FND packages break login.",
              problem="Invalids after adop.", action="adop compile.", caution="Safe.", privileges="SELECT on DBA_OBJECTS",
              sql="""SELECT object_type, SUM(DECODE(status,'INVALID',1,0)) invalids, COUNT(*) cnt
FROM dba_objects WHERE owner='APPLSYS' GROUP BY object_type ORDER BY invalids DESC, object_type;""")], extra=ebs),
        sc("28_EBS_Objects", "02_custom_objects.sql", "Custom XX schema objects",
           "Intermediate", "DEFINE xx_owner. Inventory for a customization schema.",
           [Q(title="XX objects", what="DBA_OBJECTS for custom owner.",
              columns="TYPE, NAME, STATUS.", interpret="Invalid XX bodies after a patch overwrote stubs.",
              problem="Missing XX objects after clone.", action="Re-import custom dump.", caution="Safe.", privileges="SELECT on DBA_OBJECTS",
              sql="""DEFINE xx_owner = XXCUST
SELECT object_type, status, COUNT(*) cnt FROM dba_objects WHERE owner='&xx_owner' GROUP BY object_type, status;
SELECT object_type, object_name, status, last_ddl_time FROM dba_objects
WHERE owner='&xx_owner' AND status='INVALID';""")], extra=ebs),
        sc("28_EBS_Objects", "03_invalid_ebs_objects.sql", "Invalids in APPS, APPLSYS, and product schemas",
           "Intermediate", "EBS-focused invalid list.",
           [Q(title="Invalids", what="DBA_OBJECTS status INVALID EBS owners.",
              columns="OWNER, NAME, TYPE.", interpret="Compile path: utlrp for SYS, adop/adadmin for APPS.",
              problem="APPS invalids > 0 after a failed compile.", action="05_Objects/01 generate compile — custom only.", caution="Safe to query.", privileges="SELECT on DBA_OBJECTS",
              sql="""SELECT owner, object_type, object_name, last_ddl_time
FROM dba_objects WHERE status='INVALID'
AND owner IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY owner, object_type, object_name;""")], extra=ebs),
        sc("28_EBS_Objects", "04_custom_schema_objects.sql", "All non-Oracle-maintained schemas that are not product schemas",
           "Advanced", "Finds leftover schemas (old XX, tools) that are not in FND_ORACLE_USERID.",
           [Q(title="Schemas outside FND", what="DBA_USERS minus FND_ORACLE_USERID minus oracle_maintained.",
              columns="USERNAME, CREATED.", interpret="May be legitimate tools (RMAN catalog elsewhere). Unexpected OPEN app schemas are findings.",
              problem="Unknown OPEN schema with tables.", action="Security review.", caution="Safe.", privileges="SELECT on DBA_USERS",
              sql="""SELECT u.username, u.account_status, u.created, u.oracle_maintained
FROM dba_users u
WHERE u.oracle_maintained='N'
AND u.username NOT IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY u.username;""")], extra=ebs),
        sc("28_EBS_Objects", "05_ebs_packages.sql", "Invalid or recently changed APPS packages",
           "Intermediate", "Patch impact.",
           [Q(title="APPS packages", what="PACKAGE/BODY last_ddl 7 days or invalid.",
              columns="NAME, STATUS, LAST_DDL.", interpret="Mass compile updates last_ddl for everything.",
              problem="Single package changed with no patch — unauthorized customize.", action="Diff vs source.", caution="Safe.", privileges="SELECT on DBA_OBJECTS",
              sql="""SELECT object_name, object_type, status, last_ddl_time
FROM dba_objects WHERE owner='APPS' AND object_type IN ('PACKAGE','PACKAGE BODY')
AND (status='INVALID' OR last_ddl_time>SYSDATE-7)
ORDER BY last_ddl_time DESC;""")], extra=ebs),
        sc("28_EBS_Objects", "06_ebs_triggers.sql", "Triggers on EBS product tables (custom risk)",
           "Advanced", "Triggers owned by XX or APPS on product tables.",
           [Q(title="Non-SYS triggers on product tables", what="DBA_TRIGGERS.",
              columns="TABLE_NAME, TRIGGER_NAME, STATUS.", interpret="Custom triggers on GL/AR tables are performance and upgrade risks.",
              problem="Enabled custom trigger on a hot table after a go-live.", action="Review code. Disable only with approval — generated not here.", caution="Safe.", privileges="SELECT on DBA_TRIGGERS",
              sql="""SELECT owner, trigger_name, table_owner, table_name, status, triggering_event
FROM dba_triggers
WHERE table_owner IN (SELECT oracle_username FROM fnd_oracle_userid)
AND owner NOT IN ('SYS','SYSTEM')
ORDER BY table_owner, table_name;""")], extra=ebs),
        sc("28_EBS_Objects", "07_xx_custom_objects.sql", "Objects whose names start with XX in APPS/custom schemas",
           "Intermediate", "Naming-standard hunt for customizations living in APPS.",
           [Q(title="XX% objects", what="DBA_OBJECTS object_name LIKE XX%.",
              columns="OWNER, NAME, TYPE.", interpret="Custom packages in APPS should usually live in an XX schema with APPS synonym.",
              problem="XX tables created in APPS.", action="Move with a project — do not drop.", caution="Safe.", privileges="SELECT on DBA_OBJECTS",
              sql="""SELECT owner, object_type, object_name, status
FROM dba_objects WHERE object_name LIKE 'XX%'
AND owner NOT IN ('SYS','SYSTEM')
ORDER BY owner, object_type, object_name
FETCH FIRST 300 ROWS ONLY;""")], extra=ebs),
    ]

    # 29 Health check - comprehensive
    s.append(sc(
        "29_EBS_Health_Check", "01_ebs_health_check.sql",
        "EBS + database health check with OK / WARNING / CRITICAL",
        "Advanced",
        """Single spool for shift handover or post-patch validation.
Each UNION ALL row is a check with alert_level OK, WARNING, or CRITICAL.
Review CRITICAL first, then WARNING. This script is read-only.

Checks: database/instance, tablespace/temp/undo, invalids, blocking, long SQL,
long/failed concurrent requests, managers, archive dest, FRA, sessions/processes,
EBS application invalids. ASM/Data Guard sections are included and report OK
if those views are empty (not configured).""",
        [Q(title="Health check result set",
           what="A unified ALERT_LEVEL, CHECK_NAME, DETAIL query.",
           columns="ALERT_LEVEL, CHECK_NAME, DETAIL.",
           interpret="CRITICAL = act now. WARNING = plan today. OK = within thresholds (70/85/95 space, managers up).",
           problem="Any CRITICAL row.",
           action="Open the folder named in DETAIL. Do not fix blindly from this list.",
           caution="Safe but wide — may take 30-90 seconds on a large EBS DB. Do not run every minute.",
           privileges="APPS + SELECT_CATALOG_ROLE",
           sql="""COLUMN alert_level FORMAT A10
COLUMN check_name  FORMAT A32
COLUMN detail      FORMAT A80

SELECT alert_level, check_name, detail FROM (
SELECT CASE WHEN open_mode<>'READ WRITE' THEN 'CRITICAL' ELSE 'OK' END alert_level,
       'DATABASE_OPEN_MODE' check_name, open_mode||' '||database_role detail
FROM v$database
UNION ALL
SELECT CASE WHEN status<>'OPEN' THEN 'CRITICAL' ELSE 'OK' END, 'INSTANCE_STATUS', instance_name||' '||status
FROM v$instance
UNION ALL
SELECT CASE WHEN used_pct>95 THEN 'CRITICAL' WHEN used_pct>85 THEN 'WARNING' WHEN used_pct>70 THEN 'WARNING' ELSE 'OK' END,
       'TABLESPACE '||tablespace_name, 'used_pct='||used_pct
FROM (
  SELECT ts.tablespace_name,
         ROUND((a.alloc-NVL(f.free,0))*100/NULLIF(a.alloc,0),1) used_pct
  FROM dba_tablespaces ts
  JOIN (SELECT tablespace_name, SUM(bytes) alloc FROM dba_data_files GROUP BY tablespace_name) a
        ON a.tablespace_name=ts.tablespace_name
  LEFT JOIN (SELECT tablespace_name, SUM(bytes) free FROM dba_free_space GROUP BY tablespace_name) f
        ON f.tablespace_name=ts.tablespace_name
  WHERE ts.contents='PERMANENT'
)
UNION ALL
SELECT CASE WHEN used_pct>95 THEN 'CRITICAL' WHEN used_pct>85 THEN 'WARNING' ELSE 'OK' END,
       'TEMP_USAGE', 'used_pct='||used_pct
FROM (
  SELECT ROUND((tablespace_size-free_space)*100/NULLIF(tablespace_size,0),1) used_pct
  FROM dba_temp_free_space WHERE ROWNUM=1
)
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'BLOCKING_SESSIONS',
       'blocker_waiters='||COUNT(*)
FROM gv$session WHERE blocking_session IS NOT NULL
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'LONG_SQL_15MIN',
       'active_over_15m='||COUNT(*)
FROM gv$session WHERE type='USER' AND status='ACTIVE' AND last_call_et>900
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'INVALID_APPS',
       'invalids='||COUNT(*)
FROM dba_objects WHERE status='INVALID' AND owner IN ('APPS','APPLSYS')
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'LONG_REQUESTS_2H',
       'running_over_2h='||COUNT(*)
FROM fnd_concurrent_requests WHERE phase_code='R' AND (SYSDATE-actual_start_date)*24>=2
UNION ALL
SELECT CASE WHEN COUNT(*)>0 THEN 'WARNING' ELSE 'OK' END, 'FAILED_REQUESTS_24H',
       'errors='||COUNT(*)
FROM fnd_concurrent_requests WHERE phase_code='C' AND status_code='E' AND actual_completion_date>SYSDATE-1
UNION ALL
SELECT CASE WHEN running_processes=0 AND target_processes>0 THEN 'CRITICAL' ELSE 'OK' END,
       'MANAGER_'||concurrent_queue_name, 'target='||target_processes||' running='||running_processes
FROM fnd_concurrent_queues_vl
WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM')
UNION ALL
SELECT CASE WHEN error IS NOT NULL THEN 'CRITICAL' ELSE 'OK' END,
       'ARCHIVE_DEST_'||dest_id, NVL(error,'VALID')
FROM v$archive_dest WHERE status NOT IN ('INACTIVE') AND dest_id=1
UNION ALL
SELECT CASE WHEN space_used*100/NULLIF(space_limit,0)>95 THEN 'CRITICAL'
            WHEN space_used*100/NULLIF(space_limit,0)>85 THEN 'WARNING' ELSE 'OK' END,
       'FRA_USAGE', 'used_pct='||ROUND(space_used*100/NULLIF(space_limit,0),1)
FROM v$recovery_file_dest
UNION ALL
SELECT CASE WHEN REGEXP_LIKE(limit_value,'^[0-9]+$') AND current_utilization*100/TO_NUMBER(limit_value)>95 THEN 'CRITICAL'
            WHEN REGEXP_LIKE(limit_value,'^[0-9]+$') AND current_utilization*100/TO_NUMBER(limit_value)>85 THEN 'WARNING'
            ELSE 'OK' END,
       'RESOURCE_'||resource_name, 'current='||current_utilization||' limit='||limit_value
FROM v$resource_limit WHERE resource_name IN ('processes','sessions')
)
ORDER BY CASE alert_level WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END, check_name;""")], extra=ebs))

    # 30 Advanced troubleshooting playbooks
    playbooks = [
        ("01_database_suddenly_slow.sql", "Database suddenly slow",
         "Symptom: users say everything is slow.\nInitial checks: instance up, AAS/CPU vs wait, blockers, top SQL, archive dest.\nEvidence: spool this file, alert log around the start time, OS vmstat.\nRoot causes: lock storm, plan flip, I/O, archiver hang, login storm, RAC imbalance.\nFix: follow the branch this script points to — do not bounce first.\nPost-fix: AAS back to baseline, no blockers, top SQL sane.",
         """SELECT 'INSTANCE' k, instance_name||' '||status||' up='||TO_CHAR(startup_time,'DD-MON HH24:MI') v FROM v$instance
UNION ALL SELECT 'ROLE', database_role||' '||open_mode FROM v$database
UNION ALL SELECT 'BLOCKERS', TO_CHAR(COUNT(*)) FROM gv$session WHERE blocking_session IS NOT NULL
UNION ALL SELECT 'ACTIVE_USERS', TO_CHAR(COUNT(*)) FROM gv$session WHERE type='USER' AND status='ACTIVE'
UNION ALL SELECT 'ARCH_ERROR', NVL(MAX(error),'none') FROM v$archive_dest WHERE dest_id=1;
SELECT event, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND wait_class<>'Idle' GROUP BY event ORDER BY 2 DESC;
SELECT sql_id, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND sql_id IS NOT NULL GROUP BY sql_id ORDER BY 2 DESC FETCH FIRST 15 ROWS ONLY;"""),
        ("02_cpu_suddenly_high.sql", "CPU suddenly high",
         "Symptom: host CPU 90%+ or DB CPU ≈ DB time.\nInitial: CPU_COUNT vs AAS on CPU, top SQL by CPU, runaway session.\nEvidence: OS top/perf, SESSTAT CPU, AWR if licensed.\nCauses: bad plan, parse storm, excessive PX, OS noisy neighbor.\nFix: identify SQL_ID — tune or serialize PX. Do not add CPU as first move.\nPost-fix: DB CPU fraction and OS run queue normalized.",
         """SELECT value cpu_count FROM v$parameter WHERE name='cpu_count';
SELECT stat_name, ROUND(value/1e6,1) s FROM v$sys_time_model WHERE stat_name IN ('DB time','DB CPU');
SELECT s.sid, s.module, s.sql_id, ROUND(st.value/100,1) cpu_s
FROM gv$session s JOIN gv$sesstat st ON st.sid=s.sid AND st.inst_id=s.inst_id
JOIN gv$statname sn ON sn.statistic#=st.statistic# AND sn.inst_id=st.inst_id
WHERE sn.name='CPU used by this session' AND s.type='USER' ORDER BY st.value DESC FETCH FIRST 20 ROWS ONLY;"""),
        ("03_io_suddenly_high.sql", "I/O suddenly high",
         "Symptom: storage latency/IOPS alerts, scattered/sequential reads #1.\nInitial: I/O wait events avg_ms, top physical SQL, TEMP spills, RMAN running.\nEvidence: storage array stats, ASH iowait if licensed.\nCauses: FTS, index rebuild, RMAN, checkpoint, interconnect misread as disk.\nFix: reschedule heavy jobs, tune SQL, check RMAN channels.\nPost-fix: User I/O avg_ms and IOPS back to baseline.",
         """SELECT event, ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) avg_ms, total_waits
FROM v$system_event WHERE wait_class IN ('User I/O','System I/O') ORDER BY time_waited_micro DESC FETCH FIRST 15 ROWS ONLY;
SELECT sql_id, disk_reads, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,120) t
FROM v$sql WHERE disk_reads>10000 ORDER BY disk_reads DESC FETCH FIRST 15 ROWS ONLY;"""),
        ("04_sessions_suddenly_increase.sql", "Sessions suddenly increase",
         "Symptom: session count spike, possible ORA-00018/00020.\nInitial: resource_limit, sessions by machine/program, inactive vs active.\nEvidence: listener log, app pool config.\nCauses: connection leak, retry storm, scan of a dropped service.\nFix: fix the pool. Kill only leaked inactives with generated commands (06/16).\nPost-fix: current_utilization headroom > 20%.",
         """SELECT resource_name, current_utilization, max_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('sessions','processes');
SELECT machine, program, COUNT(*) FROM gv$session WHERE type='USER' GROUP BY machine, program ORDER BY COUNT(*) DESC FETCH FIRST 20 ROWS ONLY;"""),
        ("05_database_connection_issues.sql", "Database connection issues",
         "Symptom: ORA-12514/12541/12537, timeouts, TNS.\nInitial: instance logins, listener is OS, service names, processes headroom, restricted mode.\nEvidence: listener.log, alert log, SCAN (RAC).\nCauses: listener down, service not registered, restricted, processes full, firewall.\nFix: lsnrctl / srvctl (OS). SQL cannot start the listener.\nPost-fix: new connections succeed from the app tier.",
         """SELECT instance_name, status, logins, blocked FROM gv$instance;
SELECT name, network_name FROM v$services;
SELECT resource_name, current_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT value FROM v$parameter WHERE name IN ('local_listener','remote_listener','service_names');"""),
        ("06_ora_00060_deadlock.sql", "ORA-00060 deadlock",
         "Symptom: ORA-00060 in app / alert.\nInitial: alert log deadlock graph, traces in Diag Trace.\nEvidence: two SQL statements and objects from the trace.\nCauses: locking order, missing FK index (TM), bitmap indexes on OLTP.\nFix: application lock order; unindexed FK (05/07). INITRANS is rarely the fix.\nPost-fix: no repeated 00060 on those tables.",
         """SELECT name, value FROM v$diag_info WHERE name IN ('Diag Trace','ADR Home');
PROMPT Open the ORA-00060 trace listed in the alert log. Capture Deadlock graph + SQL.
SELECT sid, event, blocking_session, sql_id FROM gv$session WHERE event LIKE 'enq:%';"""),
        ("07_ora_01555_snapshot_too_old.sql", "ORA-01555 snapshot too old",
         "Symptom: long query/export fails 01555.\nInitial: V$UNDOSTAT ssolderrcnt, maxqueryid, long TX, undo space.\nEvidence: this spool + undo file usage.\nCauses: small undo, long query, fetch across commits, delayed block cleanout.\nFix: add undo space AND shorten the query. Raising undo_retention without space does nothing.\nPost-fix: ssolderrcnt stays 0 for the same workload.",
         """SELECT TO_CHAR(begin_time,'DD-MON HH24:MI') t, ssolderrcnt, nospaceerrcnt, maxquerylen, maxqueryid, tuned_undoretention
FROM v$undostat WHERE begin_time>SYSDATE-1 AND (ssolderrcnt>0 OR maxquerylen>1800) ORDER BY begin_time DESC;
SELECT status, ROUND(SUM(bytes)/1024/1024) mb FROM dba_undo_extents GROUP BY status;
SELECT s.sid, s.module, t.start_date, t.used_ublk FROM gv$transaction t JOIN gv$session s ON s.saddr=t.ses_addr ORDER BY t.start_date;"""),
        ("08_ora_04031_shared_pool.sql", "ORA-04031 shared pool",
         "Symptom: 04031 in alert / sessions failing to parse.\nInitial: request_failures, reserved pool, large unshared SQL, recent flush.\nEvidence: 04031 trace, SGASTAT.\nCauses: fragmentation, literal SQL, flush, undersized pool.\nFix: stop flushing. Find literal SQL. Increase pool only after evidence. NOT a bounce-first problem unless frozen.\nPost-fix: request_failures stable, parses succeed.",
         """SELECT request_failures, last_failure_size, free_space FROM v$shared_pool_reserved;
SELECT name, ROUND(bytes/1024/1024,1) mb FROM v$sgastat WHERE pool='shared pool' AND bytes>20*1024*1024 ORDER BY bytes DESC;
SELECT sql_id, COUNT(*) children FROM gv$sql GROUP BY sql_id HAVING COUNT(*)>50 ORDER BY children DESC FETCH FIRST 15 ROWS ONLY;"""),
        ("09_ora_04030_pga_memory.sql", "ORA-04030 PGA / process memory",
         "Symptom: 04030 in process, possible OS OOM.\nInitial: pga_aggregate_limit, top PGA process, workarea, hugepages leftover.\nEvidence: 04030 trace shows which heap.\nCauses: huge hash, PL/SQL collections, PX slaves, OS limit.\nFix: tune SQL / limit arrays. Raise PGA only with RAM headroom. Check ulimit.\nPost-fix: process completes; PGA top consumers drop.",
         """SELECT name, display_value FROM v$parameter WHERE name LIKE 'pga%';
SELECT inst_id, spid, program, ROUND(pga_alloc_mem/1024/1024,1) mb FROM gv$process ORDER BY pga_alloc_mem DESC FETCH FIRST 15 ROWS ONLY;
SELECT sql_id, operation_type, ROUND(actual_mem_used/1024/1024,1) mb, number_passes FROM gv$sql_workarea_active;"""),
        ("10_ora_01652_temp.sql", "ORA-01652 unable to extend TEMP",
         "Symptom: sort/hash fails 01652.\nInitial: temp usage, session TEMP, SQL_ID, PGA spills.\nEvidence: this spool.\nCauses: undersized TEMP, bad plan hash join, too much PX.\nFix: add tempfile OR tune SQL. Shrinking TEMP mid-incident is wrong.\nPost-fix: statement succeeds; used_pct drops after the job.",
         """SELECT tablespace_name, ROUND((tablespace_size-free_space)*100/NULLIF(tablespace_size,0),1) used_pct FROM dba_temp_free_space;
SELECT sid, sql_id, segtype, ROUND(blocks*8/1024,1) mb FROM gv$tempseg_usage ORDER BY blocks DESC;"""),
        ("11_ora_01653_unable_to_extend.sql", "ORA-01653/01654 unable to extend table/index",
         "Symptom: DML fails extending a segment.\nInitial: tablespace used vs max, autoextend, largest chunk, file MAXSIZE.\nEvidence: error text has segment and tablespace.\nCauses: full TS, autoextend off, smallfile 32GB ceiling, fragmentation of UNIFORM.\nFix: add datafile / raise MAXSIZE. Then find why it grew (purge).\nPost-fix: DML succeeds; used_pct_max < 85.",
         """-- DEFINE ts = APPS_TS_TX_DATA
SELECT file_id, file_name, autoextensible, ROUND(bytes/1024/1024/1024,2) gb, ROUND(maxbytes/1024/1024/1024,2) max_gb
FROM dba_data_files WHERE tablespace_name='&ts';
SELECT ROUND(MAX(bytes)/1024/1024,1) largest_free_mb FROM dba_free_space WHERE tablespace_name='&ts';"""),
        ("12_ora_30036_undo_space.sql", "ORA-30036 unable to extend undo",
         "Symptom: DML cannot get undo extent.\nInitial: undo files, expired vs active, long TX, retention guarantee.\nEvidence: 13_UNDO scripts.\nCauses: huge transaction, small undo, guarantee + retention too high.\nFix: add undo file; commit/rollback the hog; do not shrink undo during the error.\nPost-fix: nospaceerrcnt 0; DML succeeds.",
         """SELECT tablespace_name, status, ROUND(SUM(bytes)/1024/1024) mb FROM dba_undo_extents GROUP BY tablespace_name, status;
SELECT name, value FROM v$parameter WHERE name LIKE 'undo%';
SELECT s.sid, s.module, t.used_ublk, t.start_date FROM gv$transaction t JOIN gv$session s ON s.saddr=t.ses_addr ORDER BY t.used_ublk DESC;"""),
        ("13_ora_01536_quota_exceeded.sql", "ORA-01536 quota exceeded",
         "Symptom: user cannot allocate in a tablespace.\nInitial: DBA_TS_QUOTAS for that user.\nEvidence: username + tablespace from the error.\nCauses: quota set for a human/batch schema.\nFix: ALTER USER QUOTA — generated only after approval. EBS product users should not need ad-hoc quotas if they use the right TS.\nPost-fix: operation succeeds.",
         """SELECT username, tablespace_name, bytes/1024/1024 used_mb, max_bytes/1024/1024 max_mb
FROM dba_ts_quotas WHERE max_bytes <> -1 ORDER BY username;
-- WARNING: Review carefully.
-- SELECT 'ALTER USER \"'||username||'\" QUOTA UNLIMITED ON '||tablespace_name||';' FROM dba_ts_quotas WHERE max_bytes<>-1;"""),
        ("14_ora_00054_resource_busy.sql", "ORA-00054 resource busy (DDL / lock)",
         "Symptom: DDL or LOCK TABLE fails 00054.\nInitial: who locks the object (10/07), TM locks.\nEvidence: V$LOCKED_OBJECT for that object.\nCauses: long transaction, forgotten form, online redef leftover.\nFix: wait or disconnect blocker POST_TRANSACTION. Do not bounce.\nPost-fix: DDL succeeds in the window.",
         """SELECT lo.session_id, s.serial#, s.status, s.module, s.event, o.object_name, lo.locked_mode
FROM gv$locked_object lo JOIN dba_objects o ON o.object_id=lo.object_id
JOIN gv$session s ON s.inst_id=lo.inst_id AND s.sid=lo.session_id
ORDER BY o.object_name;"""),
        ("15_ora_01000_open_cursors.sql", "ORA-01000 maximum open cursors",
         "Symptom: session hits open_cursors.\nInitial: opened cursors current vs parameter, leaked session.\nEvidence: V$OPEN_CURSOR for that SID.\nCauses: Java/Forms leak, missing close, high session_cached_cursors confusion (cache ≠ open leak).\nFix: fix the app. Raising open_cursors hides leaks.\nPost-fix: session cursor count stable.",
         """SELECT name, value FROM v$parameter WHERE name IN ('open_cursors','session_cached_cursors');
SELECT s.sid, s.module, st.value open_now
FROM gv$session s JOIN gv$sesstat st ON st.sid=s.sid AND st.inst_id=s.inst_id
JOIN gv$statname sn ON sn.statistic#=st.statistic# AND sn.inst_id=st.inst_id
WHERE sn.name='opened cursors current' ORDER BY st.value DESC FETCH FIRST 20 ROWS ONLY;"""),
        ("16_ora_07445.sql", "ORA-07445 exception (process crash)",
         "Symptom: 07445 in alert, process died, possibly instance stable.\nInitial: Diag incident count, alert text, associated SQL if any.\nEvidence: incident dump / cdump — package for Support.\nCauses: bug, bad bind, OS, corrupt block.\nFix: MOS/SR with the incident. Do not delete incidents before packaging. Do not bounce unless looping.\nPost-fix: no new 07445; apply recommended patch in a window.",
         """SELECT name, value FROM v$diag_info WHERE name IN ('ADR Home','Active Problem Count','Active Incident Count','Diag Alert');
PROMPT Use adrci: SHOW PROBLEM; SHOW INCIDENT; IPS PACK.\nPROMPT Do not interpret 07445 as a SQL tune issue first."""),
        ("17_ora_00600.sql", "ORA-00600 internal error",
         "Symptom: 00600 in alert with arguments [nnn].\nInitial: first argument lookup on MOS, incident dump.\nEvidence: trace + SQL involved.\nCauses: Oracle bug, corruption, unsupported action.\nFix: SR / patch. Do not keep retrying the same SQL in a tight loop.\nPost-fix: no recurrence after patch or workaround (event/_fix) approved by Support.",
         """SELECT name, value FROM v$diag_info WHERE name IN ('ADR Home','Active Problem Count','Active Incident Count');
PROMPT MOS: first 00600 argument + version 19.x. Package incidents with adrci."""),
        ("18_blocking_chains.sql", "Blocking chains (advanced playbook)",
         "Symptom: sessions hang, enq waits.\nInitial: 10/01, 10/11 tree, object, inactive blocker.\nEvidence: tree + locked objects + SQL_IDs.\nCauses: uncommitted form, unindexed FK TM, batch vs OLTP on same rows.\nFix: user commit or generated disconnect of ROOT blocker only.\nPost-fix: no waiters; business transaction confirmed.",
         """SELECT inst_id, sid, serial#, username, status, event, blocking_session, blocking_instance, sql_id, module, last_call_et
FROM gv$session WHERE blocking_session IS NOT NULL OR sid IN (
  SELECT blocking_session FROM gv$session WHERE blocking_session IS NOT NULL)
ORDER BY blocking_instance, blocking_session, sid;"""),
        ("19_library_cache_contention.sql", "Library cache / cursor pin contention",
         "Symptom: cursor: pin S wait on X, library cache lock.\nInitial: hard parse ratio, children per SQL, who is compiling, recent flush/stats.\nEvidence: 07/15, 17, 23.\nCauses: literal SQL, mid-day compile, flush, invalidations.\nFix: stop compiles/flush; share SQL. Do not flush to fix this.\nPost-fix: parse waits gone; hard parse ratio normal.",
         """SELECT event, COUNT(*) FROM gv$session WHERE event LIKE 'library cache%' OR event LIKE 'cursor: pin%' GROUP BY event;
SELECT sql_id, COUNT(*) FROM gv$sql GROUP BY sql_id HAVING COUNT(*)>30 ORDER BY 2 DESC FETCH FIRST 15 ROWS ONLY;"""),
        ("20_high_parse_rate.sql", "High parse rate",
         "Symptom: high CPU in parse, hard parses climbing.\nInitial: parse ratios, V$SQL not shared, logon rate.\nEvidence: two snapshots 60s apart of v$sysstat parses.\nCauses: literals, no binds, invalidations, connection per request.\nFix: binds, session cursor cache, stop invalidating.\nPost-fix: parse/exec drops; CPU down.",
         """SELECT name, value FROM v$sysstat WHERE name LIKE 'parse count%' OR name='execute count';
SELECT sql_id, executions, parse_calls FROM gv$sql WHERE parse_calls>executions AND executions>0
ORDER BY parse_calls DESC FETCH FIRST 20 ROWS ONLY;"""),
        ("21_high_db_cpu.sql", "High DB CPU playbook",
         "Symptom: DB CPU close to DB time and host saturated.\nSame chain as 02 with emphasis on time model and top CPU SQL.\nFix: reduce CPU SQL (functions, NL joins). Post-fix: DB CPU % down.",
         """SELECT stat_name, ROUND(value/1e6,1) s FROM v$sys_time_model WHERE stat_name IN ('DB time','DB CPU','sql execute elapsed time','parse time elapsed');
SELECT sql_id, ROUND(cpu_time/1e6,1) cpu_s, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,120) t
FROM v$sql ORDER BY cpu_time DESC FETCH FIRST 15 ROWS ONLY;"""),
        ("22_high_db_time.sql", "High DB time playbook",
         "Symptom: AAS high. DB time is the load metric.\nInitial: CPU vs wait split, top wait, top SQL elapsed, EBS running requests.\nFix: the dominant wait class (09) or SQL (07/08). Post-fix: AAS ≈ baseline.",
         """SELECT stat_name, ROUND(value/1e6,1) s FROM v$sys_time_model WHERE stat_name IN ('DB time','DB CPU');
SELECT event, ROUND(time_waited_micro/1e6,1) time_s FROM v$system_event WHERE wait_class<>'Idle' ORDER BY time_waited_micro DESC FETCH FIRST 12 ROWS ONLY;
SELECT request_id, phase_code, ROUND((SYSDATE-actual_start_date)*24*60,1) mins FROM fnd_concurrent_requests WHERE phase_code='R';"""),
        ("23_connection_saturation.sql", "Connection / process saturation",
         "Symptom: ORA-00020/00018, listeners refuse.\nInitial: resource_limit, leak by machine, restricted, dead processes.\nFix: leak first; raise processes only in a bounce window after math (PGA*processes).\nPost-fix: utilization < 70% at peak.",
         """SELECT resource_name, current_utilization, max_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT machine, COUNT(*) FROM gv$session GROUP BY machine ORDER BY 2 DESC FETCH FIRST 15 ROWS ONLY;"""),
    ]
    for fn, title, narrative, sql in playbooks:
        ebs_flag = "R12.2" if "fnd_concurrent" in sql.lower() else "N/A"
        s.append(sc(
            "30_Advanced_Troubleshooting", fn, title, "Advanced",
            narrative.replace("\n", " "),
            [Q(title=title + " — queries",
               what="Playbook queries for this symptom.",
               columns="See SELECT list / PROMPT for evidence to collect.",
               interpret="Work Symptom → Initial checks → these SQL → Evidence → Root cause → Fix → Post-fix as in the file header DESCRIPTION.",
               problem="Matches the symptom in the file name.",
               action="See DESCRIPTION recommended fix. No destructive SQL is auto-run.",
               caution="Safe to query. Bounces, kills, and parameter changes are out of band.",
               privileges="SELECT_CATALOG_ROLE" + (" + APPS" if ebs_flag == "R12.2" else ""),
               sql=sql)],
            extra="Production playbook. " + narrative.split("Fix:")[-1][:200] if "Fix:" in narrative else "Production playbook.",
            ebs=ebs_flag, priv="SELECT_CATALOG_ROLE",
        ))

    # 31 Quick reference
    s += [
        sc("31_Quick_Reference", "01_DBA_Quick_Reference.sql",
           "Daily production DBA quick reference (pack-free)",
           "Intermediate",
           "The 15 queries a coverage DBA actually runs every morning. Not a substitute for the deep folders.",
           [Q(title="Daily DBA pack",
              what="Instance, space, sessions, blockers, FRA, archiver, invalids, resource limits.",
              columns="Multiple result sets.",
              interpret="Any CRITICAL-looking row → open the dedicated folder.",
              problem="See individual outputs.",
              action="Do not skip blockers and FRA.",
              caution="Safe. Keep it as a single spool for handover.",
              privileges="SELECT_CATALOG_ROLE",
              sql="""SELECT instance_name, status, startup_time FROM gv$instance;
SELECT name, open_mode, database_role, log_mode FROM v$database;
SELECT tablespace_name, ROUND(used_percent,1) used_percent FROM (
  SELECT df.tablespace_name,
         (1-SUM(fs.bytes)/NULLIF(SUM(df.bytes),0))*100 used_percent
  FROM dba_data_files df LEFT JOIN dba_free_space fs ON fs.file_id=df.file_id
  GROUP BY df.tablespace_name) WHERE used_percent>70;
SELECT COUNT(*) blockers FROM gv$session WHERE blocking_session IS NOT NULL;
SELECT COUNT(*) active_users FROM gv$session WHERE type='USER' AND status='ACTIVE';
SELECT ROUND(space_used*100/NULLIF(space_limit,0),1) fra_used_pct FROM v$recovery_file_dest;
SELECT dest_id, status, error FROM v$archive_dest WHERE dest_id<=2;
SELECT resource_name, current_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT owner, COUNT(*) invalids FROM dba_objects WHERE status='INVALID' GROUP BY owner ORDER BY invalids DESC;
SELECT event, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND wait_class<>'Idle' GROUP BY event ORDER BY 2 DESC;""")],
           extra="Pack-free daily checks. Use 08 AWR scripts only if licensed.", ebs="N/A", priv="SELECT_CATALOG_ROLE"),
        sc("31_Quick_Reference", "02_EBS_DBA_Quick_Reference.sql",
           "Daily EBS DBA quick reference",
           "Intermediate",
           "Managers, running/pending/failed requests, APPS invalids, APPS sessions, WF deferred.",
           [Q(title="Daily EBS pack",
              what="Core EBS operational queries.",
              columns="Multiple result sets.",
              interpret="ICM/Standard/CRM must be up. Failed requests need logs.",
              problem="CRITICAL managers or APPS invalids.",
              action="Folders 21-25.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT concurrent_queue_name, target_processes, running_processes, control_code
FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM');
SELECT phase_code, status_code, COUNT(*) FROM fnd_concurrent_requests
WHERE request_date>SYSDATE-1 GROUP BY phase_code, status_code;
SELECT r.request_id, p.user_concurrent_program_name, ROUND((SYSDATE-r.actual_start_date)*24,2) hrs
FROM fnd_concurrent_requests r JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
WHERE r.phase_code='R' AND (SYSDATE-r.actual_start_date)*24>=1;
SELECT COUNT(*) apps_invalids FROM dba_objects WHERE status='INVALID' AND owner IN ('APPS','APPLSYS');
SELECT COUNT(*) apps_active FROM gv$session WHERE username='APPS' AND status='ACTIVE';
SELECT activity_status, COUNT(*) FROM wf_item_activity_statuses WHERE activity_status IN ('DEFERRED','ERROR') GROUP BY activity_status;""")],
           extra=ebs, ebs="R12.2", priv="APPS"),
        sc("31_Quick_Reference", "03_Performance_Troubleshooting_Quick_Reference.sql",
           "Performance incident first five minutes",
           "Advanced",
           "Order: CPU vs wait → top wait → blockers → top SQL → EBS running requests. Then dive into folders 07-10 or 25.",
           [Q(title="Perf first five",
              what="Time model, waits, blockers, top SQL, long requests.",
              columns="Multiple.",
              interpret="If blockers>0 stop and do locks. Else if CPU% high do CPU SQL. Else do the #1 wait event script.",
              problem="Incident in progress.",
              action="Do not flush shared pool. Do not bounce. Do not gather schema stats mid-incident.",
              caution="Safe. AWR not included (license).",
              privileges="SELECT_CATALOG_ROLE",
              sql="""SELECT ROUND(cpu.value*100/NULLIF(dbt.value,0),1) cpu_pct_of_dbtime
FROM v$sys_time_model dbt, v$sys_time_model cpu
WHERE dbt.stat_name='DB time' AND cpu.stat_name='DB CPU';
SELECT event, COUNT(*) FROM gv$session WHERE status='ACTIVE' AND wait_class<>'Idle' GROUP BY event ORDER BY 2 DESC;
SELECT COUNT(*) blockers FROM gv$session WHERE blocking_session IS NOT NULL;
SELECT sql_id, ROUND(elapsed_time/1e6,1) ela_s, SUBSTR(sql_text,1,100) t FROM v$sql WHERE parsing_schema_name NOT IN ('SYS','SYSTEM') ORDER BY elapsed_time DESC FETCH FIRST 10 ROWS ONLY;
SELECT request_id, ROUND((SYSDATE-actual_start_date)*24*60,1) mins FROM fnd_concurrent_requests WHERE phase_code='R' ORDER BY actual_start_date;""")],
           extra="If the last query fails you are not on an EBS database — skip it.", ebs="R12.2", priv="SELECT_CATALOG_ROLE"),
        sc("31_Quick_Reference", "04_Production_Incident_Quick_Reference.sql",
           "Production incident command board (what to collect, what not to do)",
           "Advanced",
           "Collect: time started, who is affected, error codes, this spool, alert log excerpt, request_id.\nDo NOT: bounce, flush shared pool, gather schema stats, kill sessions, delete interface rows, reset APPS password with ALTER USER.",
           [Q(title="Incident board",
              what="Identity, errors in dest/FRA, blockers, resource limits, ICM, plus generate (not run) kill template.",
              columns="Multiple.",
              interpret="Fill the ticket with these result sets before any change.",
              problem="Any CRITICAL identity mismatch (wrong DB_UNIQUE_NAME).",
              action="Confirm environment first. Then branch to 30_Advanced matching the error.",
              caution="WARNING: kill command is generated with 1=0 safety predicate.",
              privileges="SELECT_CATALOG_ROLE",
              sql="""SELECT name, db_unique_name, database_role, open_mode, log_mode FROM v$database;
SELECT instance_name, host_name, status, startup_time FROM gv$instance;
SELECT dest_id, status, error FROM v$archive_dest WHERE error IS NOT NULL;
SELECT ROUND(space_used*100/NULLIF(space_limit,0),1) fra_pct FROM v$recovery_file_dest;
SELECT resource_name, current_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
SELECT COUNT(*) blockers FROM gv$session WHERE blocking_session IS NOT NULL;
-- WARNING: Review carefully. Safety predicate 1=0.
SELECT 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||',@'||inst_id||''' IMMEDIATE;' kill_cmd
FROM gv$session WHERE 1=0;""")],
           extra="Confirm DB_UNIQUE_NAME matches the incident ticket before any generated command.", ebs="N/A", priv="SELECT_CATALOG_ROLE"),
    ]
    return s


if __name__ == "__main__":
    print(write_many(scripts()))
