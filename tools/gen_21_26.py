#!/usr/bin/env python3
from _writer import Query, Script, write_many

E = "EBS R12.2.x. Run as APPS (or a user with SELECT on APPLSYS/FND and APPS synonyms). Bind variables (:request_id, :hours, :username, :program_name) are provided as SQL*Plus DEFINE where useful."


def Q(**k):
    return Query(**k)


def sc(folder, file_name, purpose, difficulty, description, queries, extra=""):
    return Script(
        folder=folder,
        file_name=file_name,
        category=folder,
        purpose=purpose,
        difficulty=difficulty,
        production_use="YES",
        description=description,
        queries=queries,
        extra_header=extra or E,
        ebs="R12.2",
        privileges="APPS",
        ebs_version="R12.2.x",
    )


def scripts():
    s = []
    # ===== 21 Concurrent Managers =====
    s += [
        sc("21_EBS_Concurrent_Managers", "01_concurrent_manager_status.sql",
           "Concurrent manager target vs actual processes and enabled flag", "Intermediate",
           "First check when 'nothing is running'. Compares TARGET_PROCESSES to RUNNING_PROCESSES.",
           [Q(title="Queue status",
              what="Reads FND_CONCURRENT_QUEUES_VL for enabled managers and process counts.",
              columns="USER_CONCURRENT_QUEUE_NAME, TARGET_NODE, TARGET_PROCESSES, RUNNING_PROCESSES, ENABLED_FLAG, CONTROL_CODE.",
              interpret="RUNNING < TARGET means the manager is down or still coming up. CONTROL_CODE N=normal, D=deactivate, A=abort, T=terminate, P=suspended.",
              problem="Standard Manager TARGET>0 but RUNNING=0 during business hours.",
              action="Check ICM (11), admin scripts, and FND_CONCURRENT_PROCESSES. Do not UPDATE control_code by SQL; use Concurrent > Manager > Administer.",
              caution="Safe. Restarting managers is an apps-tier action (adcmctl).",
              privileges="APPS",
              sql="""SELECT
       concurrent_queue_name,
       user_concurrent_queue_name,
       target_node,
       enabled_flag,
       control_code,
       target_processes,
       running_processes,
       max_processes,
       cache_size
FROM   fnd_concurrent_queues_vl
ORDER BY running_processes DESC, target_processes DESC, user_concurrent_queue_name;""")]),
        sc("21_EBS_Concurrent_Managers", "02_managers_running.sql",
           "Managers that currently have OS/DB processes", "Intermediate",
           "Difference vs 01: this lists only queues with RUNNING_PROCESSES > 0 and their live process rows.",
           [Q(title="Running managers and processes",
              what="Joins queues to FND_CONCURRENT_PROCESSES with process_status_code A (active).",
              columns="QUEUE, OS_PROCESS_ID, SESSION_ID, PROCESS_STATUS_CODE, PROCESS_START_DATE.",
              interpret="A=active, K=killed, S=deactivated. Oracle SESSION_ID maps to GV$SESSION.SID on that node.",
              problem="Queue shows running_processes>0 but no active process rows — stale counts after a crash.",
              action="Relink/restart via adcmctl after checking ICM. See 10_restart_investigation.sql.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT
       q.user_concurrent_queue_name,
       q.target_node,
       p.os_process_id,
       p.oracle_process_id,
       p.session_id,
       p.process_status_code,
       p.process_start_date,
       p.manager_type
FROM   fnd_concurrent_queues_vl q
JOIN   fnd_concurrent_processes p
       ON p.concurrent_queue_id = q.concurrent_queue_id
      AND p.queue_application_id = q.application_id
WHERE  p.process_status_code = 'A'
ORDER BY q.user_concurrent_queue_name, p.process_start_date;""")]),
        sc("21_EBS_Concurrent_Managers", "03_manager_specialization.sql",
           "Specialization rules (include/exclude programs)", "Advanced",
           "Why a request sits Pending/Standby: no manager includes that program, or a specialization excludes it.",
           [Q(title="Queue content / specialization",
              what="FND_CONCURRENT_QUEUE_CONTENT joined to programs.",
              columns="QUEUE, INCLUDE_FLAG, TYPE_CODE, PROGRAM_NAME.",
              interpret="INCLUDE_FLAG I=include E=exclude. TYPE_CODE P=program C=complex R=request type.",
              problem="A custom program not included in any running manager other than Standard, and Standard is flooded.",
              action="Add specialization via Define Manager form. Not SQL inserts.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT
       q.user_concurrent_queue_name,
       c.include_flag,
       c.type_code,
       c.type_application_id,
       fcp.concurrent_program_name,
       fcp.user_concurrent_program_name
FROM   fnd_concurrent_queue_content c
JOIN   fnd_concurrent_queues_vl q
       ON q.concurrent_queue_id = c.concurrent_queue_id
      AND q.application_id = c.queue_application_id
LEFT JOIN fnd_concurrent_programs_vl fcp
       ON fcp.concurrent_program_id = c.type_id
      AND c.type_code = 'P'
ORDER BY q.user_concurrent_queue_name, c.include_flag, fcp.concurrent_program_name;""")]),
        sc("21_EBS_Concurrent_Managers", "04_manager_processes.sql",
           "All concurrent process rows including inactive", "Intermediate",
           "History of manager processes (A/K/S). Use to see crash loops.",
           [Q(title="Process history",
              what="FND_CONCURRENT_PROCESSES last 7 days.",
              columns="QUEUE, STATUS, START, OS_PID.",
              interpret="Many short-lived A→K cycles = manager dying on startup (env, library, DB connect).",
              problem="ICM restarting Standard Manager every minute.",
              action="Manager log in $APPLCSF/$APPLLOG. See 10.",
              caution="Safe. Table can be large — date filter.",
              privileges="APPS",
              sql="""SELECT
       q.user_concurrent_queue_name,
       p.process_status_code,
       p.process_start_date,
       p.process_end_date,
       p.os_process_id,
       p.session_id,
       p.logfile_name
FROM   fnd_concurrent_processes p
JOIN   fnd_concurrent_queues_vl q
       ON q.concurrent_queue_id = p.concurrent_queue_id
WHERE  p.process_start_date > SYSDATE - 7
ORDER BY p.process_start_date DESC
FETCH FIRST 200 ROWS ONLY;""")]),
        sc("21_EBS_Concurrent_Managers", "05_target_processes.sql",
           "Target processes vs work shifts (capacity plan)", "Intermediate",
           "TARGET_PROCESSES is the current shift's target. Overnight shifts may drop to 0 — looks like 'manager down'.",
           [Q(title="Targets",
              what="Queues with target and max.",
              columns="TARGET_PROCESSES, MAX_PROCESSES, SLEEP_SECONDS.",
              interpret="MAX is the ceiling. TARGET is what ICM tries to keep alive now.",
              problem="TARGET 0 during the day because the work shift ended.",
              action="07_work_shifts.sql. Fix the shift, do not just raise max.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT user_concurrent_queue_name, target_node, target_processes, max_processes,
       sleep_seconds, enabled_flag, control_code
FROM fnd_concurrent_queues_vl
ORDER BY target_processes DESC;""")]),
        sc("21_EBS_Concurrent_Managers", "06_actual_processes.sql",
           "Actual vs target with alert bands", "Intermediate",
           "RUNNING=0 and TARGET>0 is CRITICAL for ICM/Standard/CRM.",
           [Q(title="Actual vs target alerts",
              what="Computes a simple alert for under-process queues.",
              columns="TARGET, RUNNING, ALERT.",
              interpret="OK if running>=target or target=0. WARNING if running < target. CRITICAL if running=0 and target>0 for core managers.",
              problem="CRITICAL on STANDARD or INTERNAL.",
              action="Start managers. Check ICM first.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT
       concurrent_queue_name,
       user_concurrent_queue_name,
       target_processes,
       running_processes,
       CASE
         WHEN target_processes > 0 AND running_processes = 0
              AND concurrent_queue_name IN ('STANDARD','FNDICM','FNDCRM') THEN 'CRITICAL'
         WHEN target_processes > 0 AND running_processes < target_processes THEN 'WARNING'
         ELSE 'OK'
       END AS alert_level
FROM   fnd_concurrent_queues_vl
WHERE  enabled_flag = 'Y'
ORDER BY CASE alert_level WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
         user_concurrent_queue_name;""")]),
        sc("21_EBS_Concurrent_Managers", "07_work_shifts.sql",
           "Work shifts assigned to managers", "Intermediate",
           "FND_CONCURRENT_QUEUE_SIZE maps queues to work shifts (FND_WORK_SHIFTS).",
           [Q(title="Shifts",
              what="Queue to shift mapping with from/to times.",
              columns="QUEUE, SHIFT, FROM, TO, TARGET_PROCESSES.",
              interpret="A day shift 08:00-18:00 with 10 processes and night 0 explains overnight pending backlog.",
              problem="No current shift — TARGET becomes 0.",
              action="Define a 24x7 shift for Standard/ICM on production.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT
       q.user_concurrent_queue_name,
       ws.shift_name,
       qsz.min_processes,
       qsz.max_processes,
       qsz.sleep_seconds,
       ws.from_time,
       ws.to_time
FROM   fnd_concurrent_queue_size qsz
JOIN   fnd_concurrent_queues_vl q
       ON q.concurrent_queue_id = qsz.concurrent_queue_id
      AND q.application_id = qsz.queue_application_id
JOIN   fnd_work_shifts_vl ws
       ON ws.work_shift_id = qsz.work_shift_id
ORDER BY q.user_concurrent_queue_name, ws.from_time;""")]),
        sc("21_EBS_Concurrent_Managers", "08_manager_queue.sql",
           "Pending requests waiting on each manager (queue depth)", "Advanced",
           "Shows how deep each manager's pending queue is — capacity vs demand.",
           [Q(title="Pending by manager",
              what="Counts FND_CONCURRENT_REQUESTS pending, optionally mapped by program specialization (approximate via controlling manager).",
              columns="PENDING, STATUS.",
              interpret="Many Pending/Normal with free Standard Manager slots = specialization or incompatible programs. Pending/Standby = conflict (CRM).",
              problem="Hundreds Pending/Normal and Standard RUNNING=0.",
              action="15_manager_not_processing.sql. Start Standard Manager.",
              caution="Safe. Controlling_manager is set once assigned.",
              privileges="APPS",
              sql="""SELECT
       phase_code, status_code,
       DECODE(phase_code,'P','Pending','R','Running','C','Complete','I','Inactive',phase_code) phase,
       DECODE(status_code,'Q','Standby','I','Scheduled','A','Waiting','R','Normal','C','Normal',
              'E','Error','G','Warning','X','Terminated','C',status_code) status_meaning,
       COUNT(*) cnt
FROM   fnd_concurrent_requests
WHERE  phase_code IN ('P','R')
GROUP BY phase_code, status_code
ORDER BY phase_code, status_code;

SELECT controlling_manager, COUNT(*) assigned_running
FROM   fnd_concurrent_requests
WHERE  phase_code = 'R'
GROUP BY controlling_manager
ORDER BY assigned_running DESC;""")]),
        sc("21_EBS_Concurrent_Managers", "09_failed_managers.sql",
           "Managers that deactivated or have control codes other than Normal", "Advanced",
           "CONTROL_CODE not N/null or enabled N unexpectedly.",
           [Q(title="Unhealthy control codes",
              what="Filters queues with deactivate/abort/terminate or enabled N but target>0 leftover.",
              columns="CONTROL_CODE, ENABLED_FLAG.",
              interpret="D=deactivate requested. Managers stay down until you Activate.",
              problem="Someone deactivated Standard during a clone and forgot.",
              action="Activate from Administer screen. Check who via audit if available.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT concurrent_queue_name, user_concurrent_queue_name, enabled_flag, control_code,
       target_processes, running_processes, target_node
FROM fnd_concurrent_queues_vl
WHERE NVL(control_code,'N') NOT IN ('N')
   OR (enabled_flag = 'N' AND concurrent_queue_name IN ('STANDARD','FNDICM','FNDCRM'))
ORDER BY concurrent_queue_name;""")]),
        sc("21_EBS_Concurrent_Managers", "10_restart_investigation.sql",
           "Why managers die after start (logs, env, DB session)", "Advanced",
           "Symptom: adcmctl start, processes appear, then vanish. Collect logfile_name, DB connect, library issues.",
           [Q(title="Latest process logs and ICM status",
              what="Latest process rows + ICM queue + APPS account status.",
              columns="LOGFILE_NAME, PROCESS_STATUS, APPS STATUS.",
              interpret="Read the manager logfile on the concurrent node (not the DB host unless shared).",
              problem="ORA-01017 in manager log after password change. or FNDLIBR not found.",
              action="AFPASSWD/FNDCPASS per MOS. Fix APPLPTMP/LD_LIBRARY_PATH. Do not reset APPS with ALTER USER.",
              caution="Safe to query. Password changes follow EBS documented utilities only.",
              privileges="APPS + DBA_USERS",
              sql="""SELECT q.user_concurrent_queue_name, p.process_status_code, p.process_start_date,
       p.logfile_name, p.manager_type, p.session_id
FROM fnd_concurrent_processes p
JOIN fnd_concurrent_queues_vl q ON q.concurrent_queue_id = p.concurrent_queue_id
WHERE p.process_start_date > SYSDATE - 1
ORDER BY p.process_start_date DESC
FETCH FIRST 50 ROWS ONLY;

SELECT username, account_status, expiry_date FROM dba_users
WHERE username IN ('APPS','APPLSYS');

SELECT user_concurrent_queue_name, target_processes, running_processes, control_code
FROM fnd_concurrent_queues_vl
WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM');""")]),
        sc("21_EBS_Concurrent_Managers", "11_internal_concurrent_manager.sql",
           "Internal Concurrent Manager (ICM) health", "Intermediate",
           "ICM (FNDICM) starts and monitors other managers. If ICM is down, nothing recovers.",
           [Q(title="ICM queue and process",
              what="Filters FNDICM.",
              columns="RUNNING_PROCESSES, TARGET, CONTROL_CODE, OS_PID.",
              interpret="ICM should have 1 process typically (plus Service Manager on 12.2).",
              problem="ICM RUNNING=0 — entire CP stack is unmanaged.",
              action="adcmctl.sh start apps/<pwd> on the concurrent node. Check FNDCPRT/ICM log.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT * FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name = 'FNDICM';

SELECT p.*
FROM fnd_concurrent_processes p
JOIN fnd_concurrent_queues q ON q.concurrent_queue_id = p.concurrent_queue_id
WHERE q.concurrent_queue_name = 'FNDICM'
AND p.process_start_date > SYSDATE - 3
ORDER BY p.process_start_date DESC;""")]),
        sc("21_EBS_Concurrent_Managers", "12_standard_manager.sql",
           "Standard Manager depth and current requests", "Intermediate",
           "Most unspecialized programs run here. Flooding Standard is a design problem.",
           [Q(title="Standard Manager + current work",
              what="STANDARD queue + requests it is running.",
              columns="RUNNING, REQUEST_ID, PROGRAM.",
              interpret="If all Standard slots run long Gather/Reporting jobs, OLTP requests queue.",
              problem="Standard 10/10 busy on Gather Schema Stats during peak.",
              action="Specialize long jobs to a night manager. Do not just raise processes without PGA/CPU headroom.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT user_concurrent_queue_name, target_processes, running_processes, sleep_seconds
FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name = 'STANDARD';

SELECT r.request_id, r.phase_code, r.status_code, r.requested_start_date,
       u.user_name, p.user_concurrent_program_name, r.oracle_process_id, r.oracle_session_id
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id = r.concurrent_program_id
 AND p.application_id = r.program_application_id
JOIN fnd_user u ON u.user_id = r.requested_by
JOIN fnd_concurrent_queues q ON q.concurrent_queue_id = r.controlling_manager
WHERE q.concurrent_queue_name = 'STANDARD'
AND r.phase_code = 'R';""")]),
        sc("21_EBS_Concurrent_Managers", "13_conflict_resolution_manager.sql",
           "Conflict Resolution Manager (incompatibilities / Standby)", "Advanced",
           "CRM handles incompatible programs. Pending/Standby (status Q) waits for CRM. If CRM is down, Standby never clears.",
           [Q(title="CRM and Standby requests",
              what="FNDCRM status + requests in Pending Standby.",
              columns="CRM RUNNING, REQUEST_ID, PROGRAM, STATUS Q.",
              interpret="Status Q = Standby (incompatible). Status I = scheduled. Status A = waiting (unavailable manager).",
              problem="CRM down + many Q — backlog will not release.",
              action="Start CRM. Review incompatibilities in Define Program. Do not blindly delete incompatibilities.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT user_concurrent_queue_name, target_processes, running_processes
FROM fnd_concurrent_queues_vl WHERE concurrent_queue_name = 'FNDCRM';

SELECT r.request_id, r.status_code, r.phase_code, r.requested_start_date,
       p.user_concurrent_program_name, u.user_name
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id = r.concurrent_program_id
 AND p.application_id = r.program_application_id
JOIN fnd_user u ON u.user_id = r.requested_by
WHERE r.phase_code = 'P' AND r.status_code = 'Q'
ORDER BY r.requested_start_date
FETCH FIRST 80 ROWS ONLY;""")]),
        sc("21_EBS_Concurrent_Managers", "14_transaction_manager.sql",
           "Transaction managers (PO/INV/etc. AQ / TM)", "Advanced",
           "Transaction Managers process immediate/synchronous requests (PO Document Approval style). They use TIME-BASED or AQ. If TM is down, forms hang on 'transaction manager'.",
           [Q(title="Transaction managers",
              what="Queues with manager_type / user name like Transaction / PONEM / INV.",
              columns="QUEUE, TARGET, RUNNING, MANAGER_TYPE.",
              interpret="MANAGER_TYPE 1=concurrent, 2=transaction (verify on your site — also look at user name).",
              problem="PO Transaction Manager running_processes=0 — document approval hangs.",
              action="Start the product TM. Check AQ / wf_control. See MOS for TM troubleshooting.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT concurrent_queue_name, user_concurrent_queue_name, manager_type,
       target_processes, running_processes, enabled_flag, target_node
FROM fnd_concurrent_queues_vl
WHERE UPPER(user_concurrent_queue_name) LIKE '%TRANSACTION%'
   OR concurrent_queue_name LIKE '%TM%'
   OR manager_type = 2
ORDER BY user_concurrent_queue_name;""")]),
        sc("21_EBS_Concurrent_Managers", "15_manager_not_processing.sql",
           "Why a manager is not picking up requests — checklist query", "Advanced",
           "Combines the usual reasons: manager down, wrong node, specialization, pending standby, run-alone, requested_start_date future, hold flag.",
           [Q(title="Diagnostic checklist",
              what="Several result sets covering the common 'stuck pending' causes.",
              columns="Various.",
              interpret="Work top to bottom. The first CRITICAL finding is usually the cause.",
              problem="Requests Pending Normal while Standard shows free slots — look at specialization, hold, and requested_start_date.",
              action="Fix that cause. Do not restart managers as the first step if they are already running.",
              caution="Safe.",
              privileges="APPS",
              sql="""PROMPT === 1. Core managers actual vs target ===
SELECT concurrent_queue_name, target_processes, running_processes, control_code, enabled_flag, target_node
FROM fnd_concurrent_queues_vl
WHERE concurrent_queue_name IN ('FNDICM','STANDARD','FNDCRM');

PROMPT === 2. Pending breakdown ===
SELECT status_code, COUNT(*) FROM fnd_concurrent_requests
WHERE phase_code='P' GROUP BY status_code;

PROMPT === 3. Held or future-dated ===
SELECT request_id, status_code, hold_flag, requested_start_date, concurrent_program_id
FROM fnd_concurrent_requests
WHERE phase_code='P'
AND (hold_flag='Y' OR requested_start_date > SYSDATE+1/1440)
ORDER BY requested_start_date
FETCH FIRST 40 ROWS ONLY;

PROMPT === 4. Run-alone blockers ===
SELECT r.request_id, p.user_concurrent_program_name, p.run_alone_flag, r.phase_code
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE r.phase_code='R' AND p.run_alone_flag='Y';""")]),
    ]

    # ===== 22 Concurrent Requests =====
    s += [
        sc("22_EBS_Concurrent_Requests", "01_running_requests.sql",
           "Currently running concurrent requests with elapsed time", "Basic",
           "Live running list. Join to session if oracle_session_id is populated (25_EBS).",
           [Q(title="Running requests",
              what="PHASE_CODE R.",
              columns="REQUEST_ID, PROGRAM, USER, MINUTES, ORACLE_SESSION_ID, PARENT.",
              interpret="ORACLE_SESSION_ID is the SID (not always filled immediately).",
              problem="A request running many times longer than its average (13/14).",
              action="Folder 25 step 1-3. Do not cancel without functional approval.",
              caution="Safe. Cancelling is a functional action.",
              privileges="APPS",
              sql="""SELECT
       r.request_id,
       p.user_concurrent_program_name,
       u.user_name,
       r.phase_code,
       r.status_code,
       r.request_date,
       r.actual_start_date,
       ROUND((SYSDATE-r.actual_start_date)*24*60,1) AS minutes_running,
       r.oracle_session_id,
       r.oracle_process_id,
       r.parent_request_id,
       r.logfile_name,
       r.outfile_name
FROM   fnd_concurrent_requests r
JOIN   fnd_concurrent_programs_vl p
       ON p.concurrent_program_id = r.concurrent_program_id
      AND p.application_id = r.program_application_id
JOIN   fnd_user u ON u.user_id = r.requested_by
WHERE  r.phase_code = 'R'
ORDER BY r.actual_start_date;""")]),
        sc("22_EBS_Concurrent_Requests", "02_pending_requests.sql",
           "Pending requests by status (Normal/Standby/Scheduled/Inactive)", "Basic",
           "PHASE P. Status Q standby, I scheduled, A waiting, R/C pending normal (check your decode).",
           [Q(title="Pending",
              what="PHASE_CODE P.",
              columns="STATUS_CODE, REQUEST_ID, REQUESTED_START_DATE, HOLD_FLAG.",
              interpret="Future REQUESTED_START_DATE is scheduled, not stuck. HOLD_FLAG Y is held.",
              problem="Large Pending Normal queue and free manager slots.",
              action="21/15 manager not processing.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT
       r.request_id,
       r.status_code,
       r.hold_flag,
       r.requested_start_date,
       p.user_concurrent_program_name,
       u.user_name,
       ROUND((SYSDATE-r.request_date)*24*60,1) AS minutes_pending
FROM   fnd_concurrent_requests r
JOIN   fnd_concurrent_programs_vl p
       ON p.concurrent_program_id = r.concurrent_program_id
      AND p.application_id = r.program_application_id
JOIN   fnd_user u ON u.user_id = r.requested_by
WHERE  r.phase_code = 'P'
ORDER BY r.requested_start_date
FETCH FIRST 200 ROWS ONLY;""")]),
        sc("22_EBS_Concurrent_Requests", "03_completed_requests.sql",
           "Recently completed requests", "Basic",
           "PHASE C last N hours. Use for 'did it finish?'",
           [Q(title="Completed recently",
              what="PHASE_CODE C with DEFINE hours.",
              columns="REQUEST_ID, STATUS, ACTUAL_COMPLETION_DATE, ARGUMENT_TEXT.",
              interpret="Status C normal, G warning, E error, X terminated.",
              problem="N/A — inventory.",
              action="Drill into 04 if E/X.",
              caution="Safe. Table is huge — always filter time.",
              privileges="APPS",
              sql="""DEFINE hours = 8

SELECT r.request_id, r.status_code, p.user_concurrent_program_name, u.user_name,
       r.actual_start_date, r.actual_completion_date,
       ROUND((r.actual_completion_date-r.actual_start_date)*24*60,1) minutes,
       SUBSTR(r.argument_text,1,80) argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='C'
AND r.actual_completion_date > SYSDATE - &hours/24
ORDER BY r.actual_completion_date DESC
FETCH FIRST 200 ROWS ONLY;""")]),
        sc("22_EBS_Concurrent_Requests", "04_failed_requests.sql",
           "Error / warning / terminated requests", "Intermediate",
           "STATUS E, G, X. Start of every morning check.",
           [Q(title="Failed last N hours",
              what="Completed with error/warning/terminated.",
              columns="REQUEST_ID, STATUS, PROGRAM, LOGFILE.",
              interpret="E needs the request log. G may still have produced output.",
              problem="A critical period close program in E.",
              action="Read logfile on the concurrent node. Then 25 if it was long-running before fail.",
              caution="Safe.",
              privileges="APPS",
              sql="""DEFINE hours = 24

SELECT r.request_id, r.status_code, p.user_concurrent_program_name, u.user_name,
       r.actual_start_date, r.actual_completion_date,
       r.completion_text, r.logfile_name
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='C'
AND r.status_code IN ('E','G','X')
AND NVL(r.actual_completion_date,r.request_date) > SYSDATE - &hours/24
ORDER BY r.actual_completion_date DESC;""")]),
        sc("22_EBS_Concurrent_Requests", "05_long_running_requests.sql",
           "Running requests longer than 60 minutes (default)", "Intermediate",
           "Fixed 60-minute floor. Use 06 for a bind :hours.",
           [Q(title="Long running",
              what="Running and SYSDATE-actual_start_date > 1 hour.",
              columns="REQUEST_ID, HOURS, PROGRAM, SESSION.",
              interpret="Compare to average runtime (13). A 2-hour program that usually takes 10 minutes is the incident.",
              problem="Hours_running >> historical average.",
              action="25_EBS_Concurrent_SQL_Troubleshooting.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT r.request_id, p.user_concurrent_program_name, u.user_name,
       ROUND((SYSDATE-r.actual_start_date)*24,2) hours_running,
       r.oracle_session_id, r.oracle_process_id, r.parent_request_id
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='R'
AND (SYSDATE-r.actual_start_date) > 1
ORDER BY r.actual_start_date;""")]),
        sc("22_EBS_Concurrent_Requests", "06_requests_running_over_x_hours.sql",
           "Running requests longer than &hours (parameterized)", "Intermediate",
           "Difference vs 05: parameterized threshold for month-end (use 4 or 8).",
           [Q(title="Running over X hours",
              what="DEFINE hours filter.",
              columns="REQUEST_ID, HOURS_RUNNING.",
              interpret="Same as 05 with a knob.",
              problem="Any row during an SLA window.",
              action="25 master script with :request_id.",
              caution="Safe.",
              privileges="APPS",
              sql="""DEFINE hours = 4

SELECT r.request_id, p.user_concurrent_program_name, u.user_name,
       ROUND((SYSDATE-r.actual_start_date)*24,2) hours_running,
       r.oracle_session_id, r.status_code
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='R'
AND (SYSDATE-r.actual_start_date)*24 >= &hours
ORDER BY r.actual_start_date;""")]),
        sc("22_EBS_Concurrent_Requests", "07_requests_by_program.sql",
           "Request history for one program name", "Intermediate",
           "DEFINE program_name. Used for 'is this program always slow or just today'.",
           [Q(title="By program",
              what="Filter user_concurrent_program_name or concurrent_program_name.",
              columns="REQUEST_ID, STATUS, MINUTES, START.",
              interpret="A step change in duration after a patch/stats is a plan regression.",
              problem="Last 5 runs 10x slower.",
              action="25/15 plan changes + 17 stats.",
              caution="Safe. Last 14 days.",
              privileges="APPS",
              sql="""DEFINE program_name = %Gather Schema%

SELECT r.request_id, r.phase_code, r.status_code, u.user_name,
       r.actual_start_date, r.actual_completion_date,
       ROUND((NVL(r.actual_completion_date,SYSDATE)-r.actual_start_date)*24*60,1) minutes,
       SUBSTR(r.argument_text,1,100) argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE (p.user_concurrent_program_name LIKE '&program_name'
    OR p.concurrent_program_name LIKE '&program_name')
AND r.request_date > SYSDATE-14
ORDER BY r.request_id DESC
FETCH FIRST 80 ROWS ONLY;""")]),
        sc("22_EBS_Concurrent_Requests", "08_requests_by_user.sql",
           "Requests submitted by one FND user", "Intermediate",
           "DEFINE username. Finds a user flooding the managers.",
           [Q(title="By username",
              what="FND_USER.USER_NAME filter.",
              columns="REQUEST_ID, PROGRAM, PHASE.",
              interpret="A single user submitting hundreds of reports is a training/schedule issue.",
              problem="One username owns the entire pending queue.",
              action="Talk to the user. Hold or reschedule — functional.",
              caution="Safe.",
              privileges="APPS",
              sql="""DEFINE username = SYSADMIN

SELECT r.request_id, r.phase_code, r.status_code, p.user_concurrent_program_name,
       r.request_date, r.actual_start_date
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE u.user_name = '&username'
AND r.request_date > SYSDATE-3
ORDER BY r.request_id DESC
FETCH FIRST 100 ROWS ONLY;""")]),
        sc("22_EBS_Concurrent_Requests", "09_requests_by_responsibility.sql",
           "Requests by responsibility", "Intermediate",
           "Shows which responsibility is generating load (GL Super User vs a custom XX).",
           [Q(title="By responsibility",
              what="Join FND_RESPONSIBILITY_TL.",
              columns="RESPONSIBILITY_NAME, CNT, RUNNING.",
              interpret="Month-end GL responsibility spikes are expected.",
              problem="A responsibility that should be inquiry-only submitting mass updates.",
              action="Request group / menu review (20/12).",
              caution="Safe. Last 24h.",
              privileges="APPS",
              sql="""SELECT resp.responsibility_name, COUNT(*) requests,
       SUM(DECODE(r.phase_code,'R',1,0)) running,
       SUM(DECODE(r.phase_code,'P',1,0)) pending
FROM fnd_concurrent_requests r
JOIN fnd_responsibility_tl resp
       ON resp.responsibility_id = r.responsibility_id
      AND resp.language = USERENV('LANG')
WHERE r.request_date > SYSDATE-1
GROUP BY resp.responsibility_name
ORDER BY requests DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("22_EBS_Concurrent_Requests", "10_requests_by_manager.sql",
           "Running requests grouped by controlling manager", "Intermediate",
           "Which manager is busy. Complements 21/08.",
           [Q(title="By controlling manager",
              what="Join controlling_manager to queues.",
              columns="QUEUE, REQUESTS, AVG_MINUTES.",
              interpret="One specialized manager at max while Standard is idle — expected if specialized.",
              problem="All load on Standard because specialization never assigned.",
              action="21/03 specialization.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT q.user_concurrent_queue_name, COUNT(*) running_requests,
       ROUND(AVG((SYSDATE-r.actual_start_date)*24*60),1) avg_minutes
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_queues_vl q ON q.concurrent_queue_id = r.controlling_manager
WHERE r.phase_code='R'
GROUP BY q.user_concurrent_queue_name
ORDER BY running_requests DESC;""")]),
        sc("22_EBS_Concurrent_Requests", "11_requests_by_phase_status.sql",
           "Phase/status histogram (current workload picture)", "Basic",
           "Single snapshot for the bridge: how many R/P/C today.",
           [Q(title="Histogram",
              what="Group by phase_code, status_code for recent requests.",
              columns="PHASE, STATUS, CNT.",
              interpret="A wall of P/R is a manager problem. A wall of C/E is a functional/data problem.",
              problem="Pending >> Running and managers have free slots.",
              action="21/15.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT phase_code, status_code, COUNT(*) cnt
FROM fnd_concurrent_requests
WHERE request_date > SYSDATE-1
GROUP BY phase_code, status_code
ORDER BY phase_code, status_code;""")]),
        sc("22_EBS_Concurrent_Requests", "12_request_history.sql",
           "One request_id full history row (arguments, log, parent)", "Basic",
           "DEFINE request_id. The 'open this ticket' query.",
           [Q(title="Single request",
              what="Full FND_CONCURRENT_REQUESTS row plus program/user.",
              columns="All key request attributes.",
              interpret="ARGUMENT_TEXT is the submitted parameters. PARENT_REQUEST_ID walks a set.",
              problem="N/A — lookup.",
              action="If running, take ORACLE_SESSION_ID to 25/02.",
              caution="Safe.",
              privileges="APPS",
              sql="""DEFINE request_id = 0

SELECT r.request_id, r.parent_request_id, r.priority, r.phase_code, r.status_code,
       r.hold_flag, r.requested_start_date, r.actual_start_date, r.actual_completion_date,
       r.oracle_session_id, r.oracle_process_id, r.os_process_id,
       r.logfile_name, r.outfile_name, r.completion_text,
       r.argument_text,
       p.concurrent_program_name, p.user_concurrent_program_name,
       u.user_name, resp.responsibility_name
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
LEFT JOIN fnd_responsibility_tl resp ON resp.responsibility_id=r.responsibility_id AND resp.language=USERENV('LANG')
WHERE r.request_id = &request_id;""")]),
        sc("22_EBS_Concurrent_Requests", "13_average_runtime.sql",
           "Average / p95 runtime per program (last 14 days, completed normal)", "Advanced",
           "Baseline for 'is this run slow'. Uses successful completions only.",
           [Q(title="Runtime stats",
              what="Aggregates completed C/C requests.",
              columns="PROGRAM, RUNS, AVG_MIN, P95_MIN, MAX_MIN.",
              interpret="Compare a live run to AVG and P95, not MAX (MAX is often a one-off block).",
              problem="Live duration > 3x P95.",
              action="25 troubleshooting.",
              caution="Can be heavy on FND_CONCURRENT_REQUESTS — 14 day filter. Consider gathering stats on APPLSYS.FND_CONCURRENT_REQUESTS.",
              privileges="APPS",
              sql="""SELECT p.user_concurrent_program_name,
       COUNT(*) runs,
       ROUND(AVG((r.actual_completion_date-r.actual_start_date)*24*60),1) avg_min,
       ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP
             (ORDER BY (r.actual_completion_date-r.actual_start_date)*24*60),1) p95_min,
       ROUND(MAX((r.actual_completion_date-r.actual_start_date)*24*60),1) max_min
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE r.phase_code='C' AND r.status_code='C'
AND r.actual_start_date > SYSDATE-14
AND r.actual_completion_date IS NOT NULL
GROUP BY p.user_concurrent_program_name
HAVING COUNT(*) >= 3
ORDER BY avg_min DESC
FETCH FIRST 60 ROWS ONLY;""")]),
        sc("22_EBS_Concurrent_Requests", "14_top_long_running_programs.sql",
           "Programs that consumed the most concurrent runtime last 7 days", "Advanced",
           "Capacity view: which programs eat the managers. Difference vs 13: ranked by SUM(duration), not average.",
           [Q(title="Top consumers",
              what="Sum of run minutes by program.",
              columns="PROGRAM, TOTAL_HOURS, RUNS.",
              interpret="Gather stats, Create Accounting, and custom interfaces often dominate.",
              problem="A custom XX program in the top 3 unexpectedly.",
              action="26 EBS performance + 25.",
              caution="Safe with date filter.",
              privileges="APPS",
              sql="""SELECT p.user_concurrent_program_name,
       COUNT(*) runs,
       ROUND(SUM((NVL(r.actual_completion_date,SYSDATE)-r.actual_start_date)*24),1) total_hours
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE r.actual_start_date > SYSDATE-7
AND r.phase_code IN ('R','C')
GROUP BY p.user_concurrent_program_name
ORDER BY total_hours DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("22_EBS_Concurrent_Requests", "15_concurrent_request_sql.sql",
           "Map a request to SQL_ID via session / module", "Advanced",
           "Uses ORACLE_SESSION_ID and MODULE. MODULE is often the concurrent program name. Difference vs 25/02-03: this is the request-folder shortcut.",
           [Q(title="Request to SQL",
              what="Join running requests to GV$SESSION.",
              columns="REQUEST_ID, SID, SQL_ID, EVENT.",
              interpret="If ORACLE_SESSION_ID is null, match on MODULE and USERNAME APPS plus program.",
              problem="No session — the program is between DB calls or on the apps tier (host/reports).",
              action="Check the request log. Host programs may not have a DB session the whole time.",
              caution="Safe.",
              privileges="APPS + SELECT on GV_$SESSION",
              sql="""SELECT r.request_id, p.user_concurrent_program_name,
       r.oracle_session_id, s.inst_id, s.sid, s.serial#, s.sql_id, s.event, s.last_call_et
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
LEFT JOIN gv$session s ON s.sid = r.oracle_session_id AND s.username = 'APPS'
WHERE r.phase_code='R'
ORDER BY r.actual_start_date;""")]),
        sc("22_EBS_Concurrent_Requests", "16_request_wait_analysis.sql",
           "Wait events for running request sessions", "Advanced",
           "Adds EVENT/WAIT_CLASS for running requests. Pack-free (V$SESSION).",
           [Q(title="Request waits",
              what="Running requests joined to GV$SESSION waits.",
              columns="REQUEST_ID, EVENT, WAIT_CLASS, BLOCKING_SESSION.",
              interpret="Application/Concurrency → locks (10). User I/O → SQL tune. Idle → waiting on apps tier or pipe.",
              problem="Many requests on enq: TX.",
              action="10_Locks + 25/07.",
              caution="Safe.",
              privileges="APPS + GV$SESSION",
              sql="""SELECT r.request_id, p.user_concurrent_program_name,
       s.event, s.wait_class, s.seconds_in_wait, s.blocking_session, s.sql_id
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
JOIN gv$session s ON s.sid = r.oracle_session_id
WHERE r.phase_code='R'
ORDER BY s.seconds_in_wait DESC NULLS LAST;""")]),
        sc("22_EBS_Concurrent_Requests", "17_concurrent_request_performance.sql",
           "One program: last runs vs baseline (duration + status)", "Advanced",
           "DEFINE program_name. The chart you paste into a ticket.",
           [Q(title="Performance series",
              what="Last 30 completions for one program with duration.",
              columns="REQUEST_ID, MINUTES, STATUS, START.",
              interpret="Look for a cliff after a date (stats, volume, patch).",
              problem="Cliff without a volume change — plan/stats.",
              action="25/15 and 17.",
              caution="Safe.",
              privileges="APPS",
              sql="""DEFINE program_name = %Create Accounting%

SELECT r.request_id, r.status_code,
       TO_CHAR(r.actual_start_date,'DD-MON HH24:MI') started,
       ROUND((r.actual_completion_date-r.actual_start_date)*24*60,1) minutes,
       SUBSTR(r.argument_text,1,80) args
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.user_concurrent_program_name LIKE '&program_name'
AND r.phase_code='C'
AND r.actual_start_date > SYSDATE-30
ORDER BY r.actual_start_date;""")]),
    ]
    return s


if __name__ == "__main__":
    print(write_many(scripts()))
