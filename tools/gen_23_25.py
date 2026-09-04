#!/usr/bin/env python3
from _writer import Query, Script, write_many

E = "EBS R12.2.x. APPS schema. Workflow tables are typically APPS synonyms to APPLSYS."


def Q(**k):
    return Query(**k)


def sc(folder, file_name, purpose, difficulty, description, queries, extra=""):
    return Script(
        folder=folder, file_name=file_name, category=folder, purpose=purpose,
        difficulty=difficulty, production_use="YES", description=description,
        queries=queries, extra_header=extra or E, ebs="R12.2", privileges="APPS",
        ebs_version="R12.2.x",
    )


def scripts():
    s = []
    s += [
        sc("23_EBS_Workflows", "01_workflow_status.sql",
           "Open workflow items by item type and status", "Intermediate",
           "WF_ITEMS is the header. END_DATE null means still open. Huge open counts after a stuck WF background engine.",
           [Q(title="Open items by type",
              what="WF_ITEMS where end_date is null, grouped.",
              columns="ITEM_TYPE, ROOT_COUNT, OLDEST.",
              interpret="OEOH, REQAPPRV, POAPPRV commonly have open items. Compare to a known baseline.",
              problem="Open count growing every day — purge not running or engine stuck.",
              action="Check Workflow Background Process requests (22) and 06/07 listeners.",
              caution="Safe. WF_ITEMS can be large — no full scan of history.",
              privileges="APPS",
              sql="""SELECT item_type, COUNT(*) open_items,
       MIN(begin_date) oldest, MAX(begin_date) newest
FROM wf_items
WHERE end_date IS NULL
GROUP BY item_type
ORDER BY open_items DESC;""")]),
        sc("23_EBS_Workflows", "02_failed_workflows.sql",
           "Errored workflow activities (WF_ITEM_ACTIVITY_STATUSES)", "Advanced",
           "ACTIVITY_STATUS ERROR. These need the error notification / admin to retry or abort.",
           [Q(title="Errored activities",
              what="WF_ITEM_ACTIVITY_STATUSES status ERROR last 7 days.",
              columns="ITEM_TYPE, ITEM_KEY, ACTIVITY, ERROR_NAME, ERROR_MESSAGE.",
              interpret="ERROR_NAME often has the exception. ERROR_STACK is in WF_ITEM_ACTIVITY_STATUSES too (column names vary — ERROR_MESSAGE is typical).",
              problem="POAPPRV / REQAPPRV mass errors after a mailer or AMG issue.",
              action="Workflow Administrator. Do not DELETE wf tables.",
              caution="Safe. Do not update STATUS via SQL.",
              privileges="APPS",
              sql="""SELECT ias.item_type, ias.item_key, ias.process_activity,
       ias.activity_status, ias.activity_result_code,
       ias.error_name, SUBSTR(ias.error_message,1,200) error_message,
       ias.execution_time
FROM wf_item_activity_statuses ias
WHERE ias.activity_status = 'ERROR'
AND NVL(ias.notification_id,0) = NVL(ias.notification_id,0)
AND ias.execution_time > SYSDATE-7
ORDER BY ias.execution_time DESC
FETCH FIRST 100 ROWS ONLY;""")]),
        sc("23_EBS_Workflows", "03_stuck_workflows.sql",
           "Open items with no recent activity (stuck)", "Advanced",
           "Open WF_ITEMS whose latest activity is old — deferred/notified and never progressed.",
           [Q(title="Stuck open items",
              what="Open items with begin_date older than &days and still open.",
              columns="ITEM_TYPE, ITEM_KEY, BEGIN_DATE, USER_KEY.",
              interpret="A PO approval open for 90 days may be a forgotten approver — functional. Thousands stuck the same day is technical.",
              problem="Mass stuck after Workflow Background Process not running.",
              action="06 background + 04 pending activities.",
              caution="Safe. DEFINE days.",
              privileges="APPS",
              sql="""DEFINE days = 14

SELECT i.item_type, i.item_key, i.user_key, i.begin_date, i.owner_role, i.root_activity
FROM wf_items i
WHERE i.end_date IS NULL
AND i.begin_date < SYSDATE - &days
ORDER BY i.begin_date
FETCH FIRST 100 ROWS ONLY;""")]),
        sc("23_EBS_Workflows", "04_pending_activities.sql",
           "Activities in DEFERRED / NOTIFIED / WAITING", "Advanced",
           "DEFERRED is what Workflow Background Process picks up. If DEFERRED piles up, the background request is not running or is too slow.",
           [Q(title="Pending activity statuses",
              what="Group WF_ITEM_ACTIVITY_STATUSES by activity_status.",
              columns="ACTIVITY_STATUS, CNT.",
              interpret="DEFERRED high = background engine backlog. NOTIFIED high can be normal (human approvals).",
              problem="DEFERRED in the tens of thousands.",
              action="Run Workflow Background Process for that item type with Process Deferred Yes. Check 06.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT activity_status, COUNT(*) cnt
FROM wf_item_activity_statuses
GROUP BY activity_status
ORDER BY cnt DESC;

SELECT item_type, COUNT(*) deferred_cnt
FROM wf_item_activity_statuses
WHERE activity_status = 'DEFERRED'
GROUP BY item_type
ORDER BY deferred_cnt DESC;""")]),
        sc("23_EBS_Workflows", "05_workflow_errors.sql",
           "WF_ITEMS / error monitor (WF_ITEM_ACTIVITY_STATUSES error columns)", "Advanced",
           "Error name histogram for the last week.",
           [Q(title="Error names",
              what="Group errors.",
              columns="ERROR_NAME, CNT, SAMPLE_MSG.",
              interpret="Repeated WFER_... or mailer errors point to infrastructure.",
              problem="New error name after a patch.",
              action="MOS the error_name. Fix mailer / agent if notification related.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT error_name, COUNT(*) cnt,
       MAX(SUBSTR(error_message,1,120)) sample_msg
FROM wf_item_activity_statuses
WHERE activity_status='ERROR'
AND execution_time > SYSDATE-7
GROUP BY error_name
ORDER BY cnt DESC;""")]),
        sc("23_EBS_Workflows", "06_workflow_background_processes.sql",
           "Workflow Background Process concurrent requests", "Intermediate",
           "The engine that moves DEFERRED/TIMEOUT activities. If it is not scheduled, workflows stall.",
           [Q(title="Background program requests",
              what="FND_CONCURRENT_REQUESTS for FNDWFBG / Workflow Background Process.",
              columns="REQUEST_ID, PHASE, STATUS, ARGUMENTS, NEXT.",
              interpret="Should be scheduled frequently (often every few minutes per item type, site-specific).",
              problem="No successful run today and DEFERRED is high.",
              action="Submit/schedule Workflow Background Process. Do not start multiple conflicting ones without a plan.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT r.request_id, r.phase_code, r.status_code, r.requested_start_date,
       r.actual_start_date, r.actual_completion_date, r.argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.concurrent_program_name = 'FNDWFBG'
   OR p.user_concurrent_program_name LIKE 'Workflow Background%'
ORDER BY r.request_id DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("23_EBS_Workflows", "07_workflow_agent_listeners.sql",
           "Workflow agent listeners / service components (R12.2 OAM)", "Advanced",
           "FND_SVC_COMPONENTS shows Workflow Agent Listener, Mailer, etc. Container is usually the Service Manager.",
           [Q(title="Service components",
              what="FND_SVC_COMPONENTS and FND_SVC_COMP_TYPES_VL.",
              columns="COMPONENT_NAME, STARTUP_MODE, COMPONENT_STATUS.",
              interpret="STATUS RUNNING_OK / STOPPED. Mailer down = no email notifications.",
              problem="Workflow Agent Listener STOPPED — business events / AQ stall.",
              action="Start from OAM / Service Components. Check container log. SQL start is not supported.",
              caution="Safe to query.",
              privileges="APPS",
              sql="""SELECT component_name, component_status, startup_mode, component_type,
       inbound_agent_name, outbound_agent_name
FROM fnd_svc_components
ORDER BY component_type, component_name;

SELECT component_name, component_status
FROM fnd_svc_components
WHERE UPPER(component_name) LIKE '%MAILER%'
   OR UPPER(component_name) LIKE '%LISTEN%'
   OR UPPER(component_type) LIKE '%WORKFLOW%';""")]),
        sc("23_EBS_Workflows", "08_long_running_workflow_activities.sql",
           "Activities in ACTIVE / DEFERRED for a long time", "Advanced",
           "Long-running function activities can hold a background process.",
           [Q(title="Long active/deferred",
              what="WF_ITEM_ACTIVITY_STATUSES with old execution_time still not COMPLETE.",
              columns="ITEM_TYPE, ITEM_KEY, STATUS, AGE_HOURS.",
              interpret="ACTIVE for hours on a function activity may be a stuck SQL — find the session via module.",
              problem="One item_key ACTIVE since yesterday on a custom function.",
              action="25-style session hunt with MODULE like WFWK or the package name.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT item_type, item_key, activity_status,
       ROUND((SYSDATE-execution_time)*24,1) hours_since_exec,
       activity_result_code, assigned_user
FROM wf_item_activity_statuses
WHERE activity_status IN ('ACTIVE','DEFERRED','NOTIFIED')
AND execution_time < SYSDATE-1
ORDER BY execution_time
FETCH FIRST 80 ROWS ONLY;""")]),
    ]

    # 24 Interfaces
    s += [
        sc("24_EBS_Interfaces", "01_interface_tables.sql",
           "Catalog of common R12.2 interface tables and current row counts", "Intermediate",
           "Counts only — cheap if stats exist; otherwise COUNT(*) on huge interfaces can be expensive. Uses NUM_ROWS from stats as an estimate plus optional live count for small tables.",
           [Q(title="Interface table estimates",
              what="DBA_TABLES num_rows for well-known interface tables.",
              columns="OWNER, TABLE_NAME, NUM_ROWS, LAST_ANALYZED.",
              interpret="NUM_ROWS is only as good as stats. A table with millions of rows and last_analyzed months ago needs a live count in a window.",
              problem="Interface table estimated in the millions — purge/process overdue.",
              action="Module-specific scripts 08-15. Do not TRUNCATE.",
              caution="Avoid COUNT(*) on multi-GB tables during peak.",
              privileges="SELECT on DBA_TABLES",
              sql="""SELECT owner, table_name, num_rows, last_analyzed, blocks
FROM dba_tables
WHERE table_name IN (
  'AP_INVOICES_INTERFACE','AP_INVOICE_LINES_INTERFACE',
  'RA_INTERFACE_LINES_ALL','RA_INTERFACE_DISTRIBUTIONS_ALL','RA_INTERFACE_SALESCREDITS_ALL',
  'GL_INTERFACE','GL_INTERFACE_HISTORY','GL_INTERFACE_CONTROL',
  'PO_HEADERS_INTERFACE','PO_LINES_INTERFACE','PO_INTERFACE_ERRORS',
  'MTL_TRANSACTIONS_INTERFACE','MTL_TRANSACTION_LOTS_INTERFACE','MTL_SERIAL_NUMBERS_INTERFACE',
  'MTL_SYSTEM_ITEMS_INTERFACE','MTL_ITEM_CATEGORIES_INTERFACE',
  'OE_HEADERS_IFACE_ALL','OE_LINES_IFACE_ALL','OE_PAYMENTS_IFACE_ALL',
  'HR_API_TRANSACTIONS','PER_ALL_ASSIGNMENTS_F',
  'PA_TRANSACTION_INTERFACE_ALL'
)
ORDER BY NVL(num_rows,0) DESC;""")]),
        sc("24_EBS_Interfaces", "02_failed_interface_records.sql",
           "Generic pattern: records with ERROR / REJECTED status across modules", "Advanced",
           "Each module uses different status columns. This script points you at the module files and shows AP/AR/GL/PO error counts.",
           [Q(title="Error counts by module interface",
              what="Status-based counts on the most common tables.",
              columns="SOURCE, ERROR_COUNT.",
              interpret="Any non-zero ERROR after a load window is a functional + technical ticket.",
              problem="Error count growing — import program not running or data systematically bad.",
              action="Open the module script (08+). Process via the standard import concurrent program, not SQL UPDATE of status.",
              caution="Queries filter STATUS — still can be heavy. Run off-peak if tables are huge.",
              privileges="APPS",
              sql="""SELECT 'AP_INVOICES_INTERFACE' src, COUNT(*) cnt FROM ap_invoices_interface WHERE NVL(status,'X') IN ('REJECTED','ERROR')
UNION ALL
SELECT 'RA_INTERFACE_LINES_ALL', COUNT(*) FROM ra_interface_lines_all WHERE interface_line_id IS NOT NULL AND NVL(interface_status,'X') = 'E'
UNION ALL
SELECT 'GL_INTERFACE status', COUNT(*) FROM gl_interface WHERE status <> 'NEW' AND status IS NOT NULL AND status NOT LIKE 'P%'
UNION ALL
SELECT 'PO_INTERFACE_ERRORS', COUNT(*) FROM po_interface_errors
UNION ALL
SELECT 'MTL_TRANSACTIONS_INTERFACE', COUNT(*) FROM mtl_transactions_interface WHERE error_code IS NOT NULL
UNION ALL
SELECT 'PA_TRANSACTION_INTERFACE', COUNT(*) FROM pa_transaction_interface_all WHERE transaction_status_code = 'R';""")]),
        sc("24_EBS_Interfaces", "03_pending_interface_records.sql",
           "Unprocessed / NEW / PENDING interface rows", "Advanced",
           "Backlog waiting for the import program.",
           [Q(title="Pending counts",
              what="NEW/PENDING style statuses.",
              columns="SOURCE, PENDING.",
              interpret="A controlled backlog before a scheduled import is OK. Unbounded growth is not.",
              problem="Pending since > 1 day on a near-real-time interface.",
              action="Check the import concurrent program (22) and manager.",
              caution="Safe-ish; avoid peak COUNT(*) on huge GL_INTERFACE — consider date filter in module scripts.",
              privileges="APPS",
              sql="""SELECT 'AP invoices NEW' src, COUNT(*) cnt FROM ap_invoices_interface WHERE NVL(status,'NEW') IN ('NEW','PENDING')
UNION ALL
SELECT 'GL_INTERFACE NEW', COUNT(*) FROM gl_interface WHERE status = 'NEW'
UNION ALL
SELECT 'MTL_TXN PROCESS_FLAG', COUNT(*) FROM mtl_transactions_interface WHERE process_flag = '1'
UNION ALL
SELECT 'OE_HEADERS_IFACE', COUNT(*) FROM oe_headers_iface_all WHERE NVL(error_flag,'N') = 'N' AND NVL(request_id,0) = 0
UNION ALL
SELECT 'PA_TXN PENDING', COUNT(*) FROM pa_transaction_interface_all WHERE transaction_status_code = 'P';""")]),
        sc("24_EBS_Interfaces", "04_error_records.sql",
           "Sample error messages (not just counts)", "Advanced",
           "Shows a few error texts so you can classify data vs program bugs.",
           [Q(title="Sample errors",
              what="Picks error columns from PO, MTL, AP.",
              columns="TABLE, KEY, ERROR.",
              interpret="ORA- errors vs APP- / functional rejection.",
              problem="All errors the same APP- message = data contract broken.",
              action="Fix source data. Do not loop UPDATE status to NEW without fixing columns.",
              caution="FETCH FIRST only.",
              privileges="APPS",
              sql="""SELECT 'PO' src, interface_transaction_id key, error_message FROM po_interface_errors
ORDER BY creation_date DESC FETCH FIRST 20 ROWS ONLY;

SELECT 'MTL' src, transaction_interface_id key, error_code||' '||error_explanation
FROM mtl_transactions_interface
WHERE error_code IS NOT NULL
FETCH FIRST 20 ROWS ONLY;

SELECT 'AP' src, invoice_id key, status||' '||reject_lookup_code
FROM ap_invoices_interface
WHERE NVL(status,'NEW') IN ('REJECTED','ERROR')
FETCH FIRST 20 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "05_interface_processing_time.sql",
           "Import program runtimes (ties interfaces to concurrent programs)", "Intermediate",
           "Uses FND_CONCURRENT_REQUESTS for the standard import program names.",
           [Q(title="Import program durations",
              what="Recent Autoinvoice, Payables Import, Journal Import, etc.",
              columns="PROGRAM, MINUTES, STATUS.",
              interpret="Runtime growing with pending count is expected; growing with flat volume is a tune issue.",
              problem="Autoinvoice 8 hours vs 40 minutes baseline.",
              action="25 SQL troubleshooting on that request_id.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT p.user_concurrent_program_name, r.request_id, r.status_code,
       r.actual_start_date,
       ROUND((NVL(r.actual_completion_date,SYSDATE)-r.actual_start_date)*24*60,1) minutes
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.user_concurrent_program_name IN (
      'Autoinvoice Import Program','Payables Open Interface Import',
      'Journal Import','Import Standard Purchase Orders',
      'Process transaction interface','Order Import')
OR p.concurrent_program_name IN ('RAXMTR','APXIIMPT','GLLEZL','POXPOPDOI','INCTIM','OEOIMP')
AND r.request_date > SYSDATE-7
ORDER BY r.actual_start_date DESC
FETCH FIRST 60 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "06_interface_program_status.sql",
           "Is the import scheduled and succeeding?", "Intermediate",
           "Last success per import program.",
           [Q(title="Last import success",
              what="Max successful completion per program.",
              columns="PROGRAM, LAST_SUCCESS, LAST_STATUS.",
              interpret="No success in 24h on a daily interface = incident.",
              problem="Last success days ago, pending rows > 0.",
              action="Submit the import after checking managers.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT p.user_concurrent_program_name,
       MAX(CASE WHEN r.status_code='C' THEN r.actual_completion_date END) last_success,
       MAX(r.actual_completion_date) last_any,
       MAX(r.status_code) KEEP (DENSE_RANK LAST ORDER BY r.request_id) last_status
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id
 AND p.application_id=r.program_application_id
WHERE p.concurrent_program_name IN ('RAXMTR','APXIIMPT','GLLEZL','POXPOPDOI','INCTIM','OEOIMP','PAXTRTRX')
AND r.request_date > SYSDATE-14
GROUP BY p.user_concurrent_program_name;""")]),
        sc("24_EBS_Interfaces", "07_high_volume_interface_analysis.sql",
           "Which interface is largest / growing (segment size)", "Advanced",
           "Space view for interface tables — purge candidates.",
           [Q(title="Interface segment sizes",
              what="DBA_SEGMENTS for interface table names.",
              columns="TABLE, GB.",
              interpret="GL_INTERFACE_HISTORY and RA_INTERFACE_* often need purge/archive.",
              problem="Interface history bigger than transactional tables.",
              action="Standard purge programs. WARNING: no TRUNCATE.",
              caution="Safe to query.",
              privileges="SELECT on DBA_SEGMENTS",
              sql="""SELECT owner, segment_name, ROUND(bytes/1024/1024/1024,2) gb
FROM dba_segments
WHERE segment_name LIKE '%INTERFACE%'
OR segment_name LIKE '%IFACE%'
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "08_ap_interfaces.sql",
           "Payables Open Interface (AP_INVOICES_INTERFACE)", "Advanced",
           "STATUS NEW/REJECTED, reject_lookup_code. Process with Payables Open Interface Import (APXIIMPT).",
           [Q(title="AP interface backlog and rejects",
              what="Counts and sample rejects.",
              columns="STATUS, SOURCE, CNT, REJECT_LOOKUP_CODE.",
              interpret="SOURCE tells you the feeder (iSupplier, custom XX, EDI).",
              problem="REJECTED with DUPLICATE INVOICE or invalid vendor.",
              action="Fix feeder data. Reprocess via Import — do not UPDATE invoice_id.",
              caution="Safe. Large sites: add creation_date filter.",
              privileges="APPS",
              sql="""SELECT NVL(status,'NEW') status, source, COUNT(*) cnt
FROM ap_invoices_interface
GROUP BY NVL(status,'NEW'), source
ORDER BY cnt DESC;

SELECT invoice_num, source, status, reject_lookup_code, vendor_id, org_id, creation_date
FROM ap_invoices_interface
WHERE NVL(status,'NEW') IN ('REJECTED','ERROR')
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "09_ar_interfaces.sql",
           "Autoinvoice (RA_INTERFACE_LINES_ALL)", "Advanced",
           "INTERFACE_STATUS / BATCH. Errors also in RA_INTERFACE_ERRORS_ALL if present.",
           [Q(title="AR Autoinvoice backlog",
              what="Lines by request_id / interface_status.",
              columns="INTERFACE_STATUS, BATCH, CNT.",
              interpret="Lines with no request_id are waiting for Autoinvoice.",
              problem="Lines stuck after a failed RAXMTR — may need to clear request_id per MOS, not casually.",
              action="Autoinvoice Import Program. Review RA_INTERFACE_ERRORS_ALL.",
              caution="Do not DELETE interface lines without AR functional sign-off.",
              privileges="APPS",
              sql="""SELECT NVL(interface_status,'NEW') interface_status, COUNT(*) cnt,
       COUNT(DISTINCT request_id) requests
FROM ra_interface_lines_all
GROUP BY NVL(interface_status,'NEW');

SELECT * FROM ra_interface_errors_all
ORDER BY interface_line_id DESC
FETCH FIRST 30 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "10_gl_interfaces.sql",
           "GL_INTERFACE / Journal Import", "Advanced",
           "STATUS NEW is unimported. Journal Import (GLLEZL) groups by GL_INTERFACE_CONTROL.",
           [Q(title="GL interface",
              what="Status and set_of_books / ledger backlog.",
              columns="STATUS, LEDGER_ID, CNT.",
              interpret="STATUS other than NEW after import may be processed or error (site-specific codes).",
              problem="NEW rows older than the last successful Journal Import.",
              action="Run Journal Import for that group_id. Check GL_INTERFACE_CONTROL.",
              caution="COUNT(*) on GL_INTERFACE can be expensive — grouped query uses the table once.",
              privileges="APPS",
              sql="""SELECT status, set_of_books_id, ledger_id, user_je_source_name, COUNT(*) cnt,
       MIN(accounting_date) min_gl_date, MAX(accounting_date) max_gl_date
FROM gl_interface
GROUP BY status, set_of_books_id, ledger_id, user_je_source_name
ORDER BY cnt DESC;

SELECT * FROM gl_interface_control
ORDER BY je_source_name;""")]),
        sc("24_EBS_Interfaces", "11_po_interfaces.sql",
           "Purchasing document open interface", "Advanced",
           "PO_HEADERS_INTERFACE / PO_LINES_INTERFACE / PO_INTERFACE_ERRORS. Import Standard Purchase Orders.",
           [Q(title="PO interface errors and headers",
              what="Error table plus header process status.",
              columns="INTERFACE_HEADER_ID, PROCESS_CODE, ERROR_MESSAGE.",
              interpret="PROCESS_CODE PENDING/ACCEPTED/REJECTED (confirm on site).",
              problem="Errors on a high-volume punchout/XML gateway feed.",
              action="Read PO_INTERFACE_ERRORS. Fix data. Rerun Import.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT process_code, COUNT(*) cnt FROM po_headers_interface
GROUP BY process_code;

SELECT interface_header_id, table_name, column_name, error_message, creation_date
FROM po_interface_errors
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "12_inv_interfaces.sql",
           "Inventory transaction and item interfaces", "Advanced",
           "MTL_TRANSACTIONS_INTERFACE process_flag 1=pending 3=error. INCTIM processes it.",
           [Q(title="MTL transactions interface",
              what="Process flag / error code histogram.",
              columns="PROCESS_FLAG, ERROR_CODE, CNT.",
              interpret="Flag 1 backlog = INCTIM not running or locked. Flag 3 = data/period/qty errors.",
              problem="Error 40 / period not open — functional period close issue.",
              action="Inventory period / account aliases. Do not set process_flag back to 1 without fixing ERROR_EXPLANATION.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT process_flag, error_code, COUNT(*) cnt
FROM mtl_transactions_interface
GROUP BY process_flag, error_code
ORDER BY cnt DESC;

SELECT transaction_interface_id, process_flag, error_code, error_explanation,
       organization_id, transaction_type_id, creation_date
FROM mtl_transactions_interface
WHERE process_flag = '3' OR error_code IS NOT NULL
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "13_om_interfaces.sql",
           "Order Import (OE_HEADERS_IFACE_ALL / OE_LINES_IFACE_ALL)", "Advanced",
           "OEOIMP. ERROR_FLAG Y means failed. REQUEST_ID ties to the import run.",
           [Q(title="OM interface",
              what="Header error flags and sample messages.",
              columns="ERROR_FLAG, ORDER_SOURCE, CNT.",
              interpret="Lines can fail independently — always check both header and line iface.",
              problem="ERROR_FLAG Y after a pricing/item setup change.",
              action="Order Import + interface errors form. Do not delete customer orders from iface without functional OK.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT NVL(error_flag,'N') error_flag, order_source_id, COUNT(*) cnt
FROM oe_headers_iface_all
GROUP BY NVL(error_flag,'N'), order_source_id;

SELECT orig_sys_document_ref, error_flag, request_id, org_id, creation_date
FROM oe_headers_iface_all
WHERE error_flag = 'Y'
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "14_hr_interfaces.sql",
           "HR / Payroll API transactions and common staging", "Advanced",
           "HR_API_TRANSACTIONS holds SSHR / API transactions. Status and transaction_ref help find stuck approvals.",
           [Q(title="HR API transactions",
              what="HR_API_TRANSACTIONS by status.",
              columns="STATUS, CNT, OLDEST.",
              interpret="Status values are product-specific (Y/C/E etc.). Confirm against your HR patch level.",
              problem="Stuck transactions after Workflow mailer outage.",
              action="HR Workflow + API transaction monitor. Do not delete HR_API_TRANSACTIONS.",
              caution="PII — handle output as confidential.",
              privileges="APPS (HR security may hide rows)",
              sql="""SELECT status, COUNT(*) cnt, MIN(creation_date) oldest, MAX(creation_date) newest
FROM hr_api_transactions
GROUP BY status
ORDER BY cnt DESC;

SELECT transaction_id, status, transaction_ref, creation_date, selected_person_id
FROM hr_api_transactions
WHERE status NOT IN ('Y','C')
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;""")]),
        sc("24_EBS_Interfaces", "15_pa_interfaces.sql",
           "Projects transaction import (PA_TRANSACTION_INTERFACE_ALL)", "Advanced",
           "TRANSACTION_STATUS_CODE P=pending A=accepted R=rejected. PRC: Transaction Import.",
           [Q(title="PA transaction interface",
              what="Status by transaction_source.",
              columns="STATUS, SOURCE, CNT.",
              interpret="Rejected need REJECTED_REASON.",
              problem="Rejected after a resource / expenditure type change.",
              action="Fix and re-import. Do not UPDATE status to P without fixing reason.",
              caution="Safe.",
              privileges="APPS",
              sql="""SELECT transaction_status_code, transaction_source, COUNT(*) cnt
FROM pa_transaction_interface_all
GROUP BY transaction_status_code, transaction_source
ORDER BY cnt DESC;

SELECT txn_interface_id, transaction_status_code, transaction_source,
       rejected_reason, expenditure_ending_date
FROM pa_transaction_interface_all
WHERE transaction_status_code = 'R'
FETCH FIRST 40 ROWS ONLY;""")]),
    ]

    # 25 step-by-step
    steps = [
        ("01_find_long_running_request.sql", "Step 1 — find the long-running concurrent request",
         "Identify REQUEST_ID, program, user, start time, oracle_session_id.",
         """DEFINE hours = 1
SELECT r.request_id, p.user_concurrent_program_name, u.user_name,
       r.actual_start_date, ROUND((SYSDATE-r.actual_start_date)*24,2) hours_running,
       r.oracle_session_id, r.oracle_process_id, r.parent_request_id, r.argument_text
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
JOIN fnd_user u ON u.user_id=r.requested_by
WHERE r.phase_code='R' AND (SYSDATE-r.actual_start_date)*24 >= &hours
ORDER BY r.actual_start_date;"""),
        ("02_find_oracle_session.sql", "Step 2 — find the Oracle session for a request",
         "Map REQUEST_ID to INST_ID, SID, SERIAL#, SPID, MACHINE, MODULE.",
         """DEFINE request_id = 0
SELECT r.request_id, r.oracle_session_id,
       s.inst_id, s.sid, s.serial#, s.status, s.event, s.sql_id, s.module, s.machine, s.program,
       p.spid, ROUND(p.pga_alloc_mem/1024/1024,1) pga_mb
FROM fnd_concurrent_requests r
LEFT JOIN gv$session s ON s.sid = r.oracle_session_id AND s.username='APPS'
LEFT JOIN gv$process p ON p.inst_id=s.inst_id AND p.addr=s.paddr
WHERE r.request_id = &request_id;
-- Fallback if oracle_session_id is null:
SELECT s.inst_id, s.sid, s.serial#, s.sql_id, s.event, s.module, s.action
FROM gv$session s
WHERE s.username='APPS'
AND (s.module LIKE '%'||(SELECT concurrent_program_name FROM fnd_concurrent_programs_vl p
      JOIN fnd_concurrent_requests r ON r.concurrent_program_id=p.concurrent_program_id
      WHERE r.request_id=&request_id AND ROWNUM=1)||'%'
     OR s.action LIKE '%'||TO_CHAR(&request_id)||'%');"""),
        ("03_find_sql_id.sql", "Step 3 — capture SQL_ID (current and previous)",
         "SQL_ID / PREV_SQL_ID / SQL_CHILD_NUMBER for the session.",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT inst_id, sid, serial#, sql_id, sql_child_number, prev_sql_id, event, last_call_et, blocking_session
FROM gv$session WHERE inst_id=&inst AND sid=&sid;"""),
        ("04_find_sql_text.sql", "Step 4 — SQL text",
         "Full text from GV$SQL / V$SQLAREA.",
         """DEFINE sql_id = 0w6u2qj2zn5hs
SELECT sql_id, child_number, plan_hash_value, parsing_schema_name, module, sql_fulltext
FROM gv$sql WHERE sql_id='&sql_id';"""),
        ("05_find_execution_plan.sql", "Step 5 — execution plan",
         "DISPLAY_CURSOR for the child. No Tuning Pack required.",
         """DEFINE sql_id = 0w6u2qj2zn5hs
DEFINE child = 0
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', &child, 'TYPICAL +PEEKED_BINDS'));"""),
        ("06_check_wait_event.sql", "Step 6 — current and session wait events",
         "What the session is waiting on now and cumulatively.",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT event, wait_class, state, seconds_in_wait, p1text, p1, p2text, p2
FROM gv$session WHERE inst_id=&inst AND sid=&sid;
SELECT event, total_waits, ROUND(time_waited_micro/1e6,1) time_s
FROM gv$session_event WHERE inst_id=&inst AND sid=&sid AND wait_class<>'Idle'
ORDER BY time_waited_micro DESC;"""),
        ("07_check_blocking_session.sql", "Step 7 — blocker for the request session",
         "If BLOCKING_SESSION is set, identify the blocker (often an inactive form).",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT w.sid waiter, w.event, w.sql_id, w.blocking_instance, w.blocking_session,
       b.username, b.status, b.module, b.machine, b.program, b.last_call_et, b.sql_id blocker_sql
FROM gv$session w
LEFT JOIN gv$session b ON b.inst_id=NVL(w.blocking_instance,w.inst_id) AND b.sid=w.blocking_session
WHERE w.inst_id=&inst AND w.sid=&sid;"""),
        ("08_check_cpu_consumption.sql", "Step 8 — CPU used by the session",
         "SESSTAT CPU used by this session (cumulative this login).",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT sn.name, st.value
FROM gv$sesstat st JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE st.inst_id=&inst AND st.sid=&sid
AND sn.name IN ('CPU used by this session','parse time cpu','recursive cpu usage');"""),
        ("09_check_logical_reads.sql", "Step 9 — logical I/O (buffer gets)",
         "session logical reads / consistent gets.",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT sn.name, st.value
FROM gv$sesstat st JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE st.inst_id=&inst AND st.sid=&sid
AND sn.name IN ('session logical reads','consistent gets','db block gets','buffer is pinned count');"""),
        ("10_check_physical_reads.sql", "Step 10 — physical reads",
         "physical reads / direct reads.",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT sn.name, st.value
FROM gv$sesstat st JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE st.inst_id=&inst AND st.sid=&sid
AND sn.name LIKE 'physical read%';"""),
        ("11_check_temp_usage.sql", "Step 11 — TEMP for the session",
         "GV$TEMPSEG_USAGE for the SID.",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT inst_id, sid, sql_id, segtype, ROUND(blocks*8/1024,1) mb
FROM gv$tempseg_usage WHERE inst_id=&inst AND sid=&sid;"""),
        ("12_check_pga_usage.sql", "Step 12 — PGA for the session",
         "Process PGA used/alloc.",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT s.sid, ROUND(p.pga_used_mem/1024/1024,1) used_mb,
       ROUND(p.pga_alloc_mem/1024/1024,1) alloc_mb, p.spid
FROM gv$session s JOIN gv$process p ON p.inst_id=s.inst_id AND p.addr=s.paddr
WHERE s.inst_id=&inst AND s.sid=&sid;"""),
        ("13_check_io.sql", "Step 13 — I/O bytes and requests",
         "physical read/write bytes.",
         """DEFINE sid = 0
DEFINE inst = 1
SELECT sn.name, st.value
FROM gv$sesstat st JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
WHERE st.inst_id=&inst AND st.sid=&sid
AND (sn.name LIKE 'physical %bytes' OR sn.name IN ('physical reads','physical writes','redo size'));"""),
        ("14_check_execution_count.sql", "Step 14 — executions of the SQL_ID",
         "Is this a long single execution or a loop?",
         """DEFINE sql_id = 0w6u2qj2zn5hs
SELECT inst_id, child_number, executions, ROUND(elapsed_time/1e6,1) ela_s,
       ROUND(elapsed_time/NULLIF(executions,0)/1e6,3) ela_per_exec_s
FROM gv$sql WHERE sql_id='&sql_id';"""),
        ("15_check_execution_plan_changes.sql", "Step 15 — plan hashes over time (AWR)",
         "LICENSING: Diagnostics Pack for DBA_HIST_SQLSTAT.",
         """DEFINE sql_id = 0w6u2qj2zn5hs
SELECT TO_CHAR(sn.begin_interval_time,'DD-MON HH24:MI') snap_time, st.plan_hash_value,
       st.executions_delta,
       ROUND(st.elapsed_time_delta/NULLIF(st.executions_delta,0)/1e6,3) ela_per_exec_s
FROM dba_hist_sqlstat st
JOIN dba_hist_snapshot sn ON sn.snap_id=st.snap_id AND sn.dbid=st.dbid AND sn.instance_number=st.instance_number
WHERE st.sql_id='&sql_id' AND sn.begin_interval_time>SYSDATE-14
ORDER BY sn.begin_interval_time;"""),
        ("16_check_bind_variables.sql", "Step 16 — captured binds",
         "Peeked binds that may explain a bad plan.",
         """DEFINE sql_id = 0w6u2qj2zn5hs
SELECT child_number, name, datatype_string, value_string, last_captured
FROM v$sql_bind_capture WHERE sql_id='&sql_id' ORDER BY child_number, position;"""),
        ("17_check_optimizer_statistics.sql", "Step 17 — stats on objects in the plan",
         "Stale/missing stats for objects referenced by the SQL_ID plan.",
         """DEFINE sql_id = 0w6u2qj2zn5hs
SELECT DISTINCT p.object_owner, p.object_name, p.object_type,
       t.num_rows, t.last_analyzed, t.stale_stats
FROM v$sql_plan p
LEFT JOIN dba_tab_statistics t
       ON t.owner=p.object_owner AND t.table_name=p.object_name AND t.object_type='TABLE'
WHERE p.sql_id='&sql_id'
AND p.object_name IS NOT NULL
ORDER BY p.object_owner, p.object_name;"""),
        ("18_check_indexes.sql", "Step 18 — indexes on tables used by the SQL",
         "Index list + unusable flag for plan objects.",
         """DEFINE sql_id = 0w6u2qj2zn5hs
SELECT i.table_owner, i.table_name, i.index_name, i.uniqueness, i.status, i.visibility
FROM dba_indexes i
WHERE (i.table_owner, i.table_name) IN (
  SELECT object_owner, object_name FROM v$sql_plan
  WHERE sql_id='&sql_id' AND operation LIKE 'TABLE%')
ORDER BY i.table_owner, i.table_name, i.index_name;"""),
        ("19_check_table_growth.sql", "Step 19 — size of tables in the plan",
         "Segment size — a 10x data growth explains a 10x runtime without a plan change.",
         """DEFINE sql_id = 0w6u2qj2zn5hs
SELECT s.owner, s.segment_name, s.segment_type, ROUND(s.bytes/1024/1024/1024,2) gb
FROM dba_segments s
WHERE (s.owner, s.segment_name) IN (
  SELECT object_owner, object_name FROM v$sql_plan WHERE sql_id='&sql_id' AND object_name IS NOT NULL)
ORDER BY s.bytes DESC;"""),
        ("20_check_concurrent_manager_impact.sql", "Step 20 — is this request blocking the managers?",
         "Same program count running, Standard Manager slots, pending behind it (run_alone).",
         """DEFINE request_id = 0
SELECT p.run_alone_flag, p.user_concurrent_program_name,
       q.user_concurrent_queue_name, q.target_processes, q.running_processes
FROM fnd_concurrent_requests r
JOIN fnd_concurrent_programs_vl p ON p.concurrent_program_id=r.concurrent_program_id AND p.application_id=r.program_application_id
LEFT JOIN fnd_concurrent_queues_vl q ON q.concurrent_queue_id=r.controlling_manager
WHERE r.request_id=&request_id;

SELECT COUNT(*) other_running_same_program
FROM fnd_concurrent_requests r2
JOIN fnd_concurrent_requests r1 ON r1.concurrent_program_id=r2.concurrent_program_id
WHERE r1.request_id=&request_id AND r2.phase_code='R' AND r2.request_id<>&request_id;"""),
    ]
    for fn, purpose, desc, sql in steps:
        notes = "Diagnostics Pack required." if "dba_hist" in sql.lower() else ""
        s.append(sc(
            "25_EBS_Concurrent_SQL_Troubleshooting", fn, purpose, "Advanced",
            desc + " Part of the Request→Session→SQL_ID→Plan→Wait→Blocker→CPU/IO/TEMP/PGA→Root cause chain.",
            [Q(title=purpose, what=desc,
               columns="See SELECT list.",
               interpret="Capture the output into the incident ticket before changing anything.",
               problem="Missing session or SQL_ID means the program is not in a DB call — check the request log.",
               action="Continue the next numbered script. Do not skip to kill.",
               caution="Safe. AWR script needs Diagnostics Pack." if notes else "Safe.",
               privileges="APPS + SELECT_CATALOG_ROLE",
               sql=sql, notes=notes)],
            extra=E + (" " + notes if notes else ""),
        ))

    s.append(sc(
        "25_EBS_Concurrent_SQL_Troubleshooting", "21_master_troubleshooting.sql",
        "Master correlation: Request → Session → SQL → Plan → Wait → Blocker → Resources → Action",
        "Advanced",
        """Run this first during an EBS long-request incident. It correlates the chain in one spool.
Then use scripts 01-20 to drill the finding.

Chain:
  Concurrent Request
       ↓
  Oracle Session (SID/SERIAL@INST)
       ↓
  SQL_ID / SQL text
       ↓
  Execution plan hash
       ↓
  Wait event / blocking session
       ↓
  CPU / I/O / TEMP / PGA
       ↓
  Root cause hypothesis
       ↓
  Recommended action (tune / stats / lock / manager / cancel)""",
        [Q(title="Master correlation for &request_id",
           what="Single script joining FND_CONCURRENT_REQUESTS, GV$SESSION, GV$SQL, GV$PROCESS, temp, locks.",
           columns="REQUEST_ID, SID, SQL_ID, EVENT, BLOCKER, PGA_MB, TEMP_MB, ELA_S.",
           interpret="Read top to bottom. If EVENT is enq:, go to locks. If TEMP_MB high, spill. If SQL_ID null, apps-tier program.",
           problem="Hours_running high AND blocker present — do not tune SQL, clear the lock.",
           action="Follow the recommended_action CASE. Cancel request only with functional approval (not done here).",
           caution="Safe. Does not kill or cancel. Diagnostics Pack not required.",
           privileges="APPS + SELECT on GV$ views",
           sql="""DEFINE request_id = 0

COLUMN recommended_action FORMAT A80

SELECT
       r.request_id,
       p.user_concurrent_program_name AS program,
       u.user_name,
       ROUND((SYSDATE-r.actual_start_date)*24*60,1) AS minutes_running,
       s.inst_id, s.sid, s.serial#,
       s.sql_id,
       s.event AS wait_event,
       s.wait_class,
       s.blocking_session,
       s.blocking_instance,
       ROUND(pr.pga_alloc_mem/1024/1024,1) AS pga_mb,
       (SELECT ROUND(SUM(t.blocks)*8/1024,1) FROM gv$tempseg_usage t
         WHERE t.inst_id=s.inst_id AND t.sid=s.sid) AS temp_mb,
       q.plan_hash_value,
       ROUND(q.elapsed_time/1e6,1) AS sql_ela_s,
       CASE
         WHEN s.sid IS NULL THEN 'No DB session — check request log / host executable'
         WHEN s.blocking_session IS NOT NULL THEN 'LOCK: clear root blocker (folder 10). Do not tune yet'
         WHEN s.event LIKE 'enq:%' THEN 'LOCK/enqueue — folder 10 and 25/07'
         WHEN NVL((SELECT SUM(t.blocks) FROM gv$tempseg_usage t WHERE t.inst_id=s.inst_id AND t.sid=s.sid),0) > 128000
              THEN 'TEMP spill — 14_TEMP + tune hash/sort (25/11)'
         WHEN s.event LIKE 'db file scattered%' OR s.event LIKE 'direct path read%'
              THEN 'FTS/I/O — plan + stats (25/05, 17, 18)'
         WHEN s.event LIKE 'log file sync%' THEN 'Commit wait — redo/commit rate, not the SQL shape'
         ELSE 'Review plan/binds/stats (25/05, 15, 16, 17) then 08_SQL_Tuning'
       END AS recommended_action
FROM   fnd_concurrent_requests r
JOIN   fnd_concurrent_programs_vl p
       ON p.concurrent_program_id = r.concurrent_program_id
      AND p.application_id = r.program_application_id
JOIN   fnd_user u ON u.user_id = r.requested_by
LEFT JOIN gv$session s ON s.sid = r.oracle_session_id AND s.username = 'APPS'
LEFT JOIN gv$process pr ON pr.inst_id = s.inst_id AND pr.addr = s.paddr
LEFT JOIN gv$sql q ON q.inst_id = s.inst_id AND q.sql_id = s.sql_id AND q.child_number = s.sql_child_number
WHERE  r.request_id = &request_id;

PROMPT Next: run 04 (SQL text), 05 (plan), 06-20 as indicated by recommended_action.""")],
    ))
    return s


if __name__ == "__main__":
    print(write_many(scripts()))
