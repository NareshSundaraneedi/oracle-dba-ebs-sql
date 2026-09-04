#!/usr/bin/env python3
from _writer import Query, Script, write_many


def q(title, what, columns, interpret, problem, action, caution, privs, sql, notes=""):
    return Query(title, sql, what, columns, interpret, problem, action, caution, privs, notes)


def S(file_name, purpose, difficulty, desc, queries, extra=""):
    return Script(
        folder="20_Oracle_EBS",
        file_name=file_name,
        category="20_Oracle_EBS",
        purpose=purpose,
        difficulty=difficulty,
        production_use="YES",
        description=desc,
        queries=queries,
        extra_header=extra or "EBS R12.2.x. Connect to the EBS database (usually the APPS schema or a user with APPS grants). Many views are APPS synonyms.",
        ebs="R12.2",
        privileges="APPS or SELECT on APPLSYS / FND tables",
        ebs_version="R12.2.x",
    )


def scripts():
    apps = "Requires EBS R12.2 objects (APPLSYS/APPS). Will fail on a non-EBS database."
    return [
        S("01_ebs_database_information.sql", "EBS database name, apps user, and character set context",
          "Basic",
          "First confirmation you are on the intended EBS environment (PROD vs clone).",
          [q("Database plus APPS user status",
             "V$DATABASE plus DBA_USERS for APPS/APPLSYS/APPLSYSPUB.",
             "DB_UNIQUE_NAME, APPS STATUS, EXPIRY.",
             "APPS must be OPEN and not in EXPIRED(GRACE) on a running EBS.",
             "APPS locked/expired — login and concurrent processing fail.",
             "Do not reset APPS password with generic ALTER USER; use the supported EBS password utility (FNDCPASS / AFPASSWD) per MOS.",
             "Safe to query.",
             "SELECT on V_$DATABASE, DBA_USERS",
             """SELECT name, db_unique_name, database_role, open_mode, log_mode FROM v$database;
SELECT username, account_status, expiry_date, lock_date, profile
FROM dba_users
WHERE username IN ('APPS','APPLSYS','APPLSYSPUB','APPS_NE','SYSTEM')
ORDER BY username;""")], extra=apps),
        S("02_ebs_application_information.sql", "Registered applications and basepath",
          "Basic",
          "FND_APPLICATION lists product short names (GL, AR, XX). Used to confirm custom apps are registered.",
          [q("FND applications",
             "FND_APPLICATION_VL.",
             "APPLICATION_SHORT_NAME, APPLICATION_NAME, BASEPATH.",
             "Custom XX apps should be present after a clone if they were in the export.",
             "Missing custom application after a refresh.",
             "Re-register via System Administrator or AD utilities — not SQL inserts.",
             "Safe.",
             "APPS",
             """SELECT application_id, application_short_name, application_name, basepath
FROM fnd_application_vl
ORDER BY application_short_name;""")], extra=apps),
        S("03_ebs_release_version.sql", "EBS release, RDBMS, and product versions",
          "Basic",
          "FND_PRODUCT_GROUPS / FND_PRODUCT_INSTALLATIONS show the EBS release (12.2.x) and which products are installed at which patch level.",
          [q("Release and product installations",
             "FND_PRODUCT_GROUPS and FND_PRODUCT_INSTALLATIONS.",
             "RELEASE_NAME, PRODUCT_VERSION, STATUS, PATCH_LEVEL.",
             "RELEASE_NAME like 12.2.n. STATUS I = installed. PATCH_LEVEL R12.AD.C.Delta.n etc.",
             "RELEASE_NAME not matching the expected RU. Product STATUS N that should be installed.",
             "Do not update these tables by hand. Use adop / adpatch history.",
             "Safe.",
             "APPS",
             """SELECT release_name, product_group_id, applications_system_name
FROM fnd_product_groups;

SELECT fa.application_short_name, fpi.product_version, fpi.status, fpi.patch_level, fpi.tablespace, fpi.index_tablespace
FROM fnd_product_installations fpi
JOIN fnd_application fa ON fa.application_id = fpi.application_id
WHERE fpi.status = 'I'
ORDER BY fa.application_short_name;""")], extra=apps),
        S("04_ad_txk_versions.sql", "AD and TXK codelevels (R12.2 adop prerequisites)",
          "Intermediate",
          "R12.2 patching requires known AD/TXK codelevels. AD_RELEASES / patch history and FND_PRODUCT_INSTALLATIONS patch_level for AD and TXK.",
          [q("AD/TXK patch levels",
             "Product installations for AD and AK/TXK plus applied patches sample.",
             "PATCH_LEVEL, PATCH_NAME.",
             "Compare to MOS for the EBS 12.2 RU you intend to apply.",
             "AD/TXK below the minimum for an upcoming RU.",
             "Apply the required AD/TXK patches with adop — not SQL.",
             "Safe. AD_APPLIED_PATCHES can be large — filtered.",
             "APPS",
             """SELECT fa.application_short_name, fpi.patch_level, fpi.product_version, fpi.status
FROM fnd_product_installations fpi
JOIN fnd_application fa ON fa.application_id = fpi.application_id
WHERE fa.application_short_name IN ('AD','FND','AU','AK','TXK')
   OR fpi.patch_level LIKE '%TXK%'
   OR fpi.patch_level LIKE '%AD.%';

SELECT patch_name, patch_type, creation_date
FROM ad_applied_patches
WHERE patch_name LIKE '%AD%' OR patch_name LIKE '%TXK%'
ORDER BY creation_date DESC
FETCH FIRST 40 ROWS ONLY;""")], extra=apps),
        S("05_applsys_information.sql", "APPLSYS schema objects and invalids",
          "Intermediate",
          "APPLSYS owns FND tables. Invalid APPLSYS objects break login and concurrent processing.",
          [q("APPLSYS invalids and size",
             "DBA_OBJECTS / DBA_SEGMENTS for APPLSYS.",
             "INVALIDS, SIZE_GB.",
             "Zero invalids expected after a successful compile.",
             "Invalid FND packages after a failed adop fs_clone.",
             "Compile via adadmin / adop. Do not compile APPLSYS as a random user.",
             "Safe.",
             "SELECT on DBA_OBJECTS, DBA_SEGMENTS",
             """SELECT status, COUNT(*) FROM dba_objects WHERE owner='APPLSYS' GROUP BY status;
SELECT object_type, object_name FROM dba_objects WHERE owner='APPLSYS' AND status='INVALID' ORDER BY 1,2;
SELECT ROUND(SUM(bytes)/1024/1024/1024,2) applsys_gb FROM dba_segments WHERE owner='APPLSYS';""")], extra=apps),
        S("06_fnd_schemas.sql", "FND / Oracle user mapping (FND_ORACLE_USERID)",
          "Intermediate",
          "Maps EBS application ids to Oracle schemas (GL -> GL, custom XX -> XXCUST).",
          [q("Oracle userids",
             "FND_ORACLE_USERID.",
             "ORACLE_USERNAME, READ_ONLY_FLAG, ENABLED_FLAG.",
             "APPS is the runtime user. Product schemas should typically not be used for ad-hoc login.",
             "A product schema ENABLED unexpectedly or APPS missing.",
             "Do not insert into FND_ORACLE_USERID. Use AD utilities.",
             "Safe.",
             "APPS",
             """SELECT oracle_id, oracle_username, enabled_flag, read_only_flag, install_group_num
FROM fnd_oracle_userid
ORDER BY oracle_username;""")], extra=apps),
        S("07_ebs_users.sql", "FND_USER application users (not database users)",
          "Basic",
          "EBS end users live in FND_USER. Difference vs 27_EBS_Users: this is a basic inventory; folder 27 has end-date, responsibilities, and hygiene.",
          [q("FND users sample and counts",
             "FND_USER counts and recently created.",
             "USER_NAME, EMAIL, END_DATE, LAST_LOGON.",
             "END_DATE < SYSDATE means the user cannot log in.",
             "SYSADMIN end-dated. Guest user modified.",
             "Use the Users form / User Management. Do not UPDATE FND_USER.END_DATE by SQL except with approved procedure.",
             "Safe. Do not dump all password hashes.",
             "APPS",
             """SELECT COUNT(*) total_users,
       SUM(CASE WHEN NVL(end_date,SYSDATE+1) > SYSDATE THEN 1 ELSE 0 END) active_users
FROM fnd_user;

SELECT user_name, description, email_address, start_date, end_date, last_logon_date
FROM fnd_user
ORDER BY NVL(last_logon_date, start_date) DESC
FETCH FIRST 50 ROWS ONLY;""")], extra=apps),
        S("08_responsibilities.sql", "Responsibility inventory",
          "Basic",
          "FND_RESPONSIBILITY_VL. Folder 27 has user-to-resp assignments.",
          [q("Responsibilities",
             "FND_RESPONSIBILITY_VL.",
             "RESPONSIBILITY_NAME, APPLICATION, END_DATE, DATA_GROUP.",
             "End-dated responsibilities should not be assigned to new users.",
             "A custom responsibility missing after clone (data group / request group not imported).",
             "Recreate via form or FNDLOAD — not INSERT.",
             "Safe. Result can be large — first 200.",
             "APPS",
             """SELECT responsibility_id, responsibility_name, application_id, start_date, end_date,
       data_group_id, menu_id, request_group_id
FROM fnd_responsibility_vl
ORDER BY responsibility_name
FETCH FIRST 200 ROWS ONLY;""")], extra=apps),
        S("09_menus.sql", "Menus and menu entries for a responsibility",
          "Intermediate",
          "Diagnose 'function not available' by walking MENU_ID from the responsibility.",
          [q("Menu tree for one responsibility",
             "Joins FND_RESPONSIBILITY_VL to FND_MENUS and FND_MENU_ENTRIES_VL.",
             "MENU_NAME, PROMPT, FUNCTION_NAME.",
             "Missing prompt/function = menu not compiled or entry excluded.",
             "Users cannot see a form that exists — often menu or exclusion.",
             "Use Function Security / Menu form. Compile menus after FNDLOAD.",
             "Safe. Bind responsibility name.",
             "APPS",
             """DEFINE resp_name = System Administrator

SELECT r.responsibility_name, m.menu_name, m.user_menu_name,
       e.entry_sequence, e.prompt, f.function_name, f.user_function_name
FROM fnd_responsibility_vl r
JOIN fnd_menus_vl m ON m.menu_id = r.menu_id
LEFT JOIN fnd_menu_entries_vl e ON e.menu_id = m.menu_id
LEFT JOIN fnd_form_functions_vl f ON f.function_id = e.function_id
WHERE r.responsibility_name = '&resp_name'
ORDER BY e.entry_sequence;""")], extra=apps),
        S("10_concurrent_programs.sql", "Concurrent program definitions",
          "Intermediate",
          "FND_CONCURRENT_PROGRAMS_VL — executable, run-alone, enabled. Difference vs folder 22: this is metadata, not runtime requests.",
          [q("Programs matching a name",
             "Search by program name.",
             "CONCURRENT_PROGRAM_NAME, USER_CONCURRENT_PROGRAM_NAME, ENABLED, EXECUTABLE.",
             "ENABLED_FLAG N explains why users cannot submit.",
             "Program missing after a patch (custom XX overwritten).",
             "Restore from FNDLOAD ldt. Do not insert into FND_CONCURRENT_PROGRAMS.",
             "Safe.",
             "APPS",
             """DEFINE prog = %Gather%

SELECT fcp.concurrent_program_name, fcp.user_concurrent_program_name,
       fcp.enabled_flag, fcp.run_alone_flag, fcp.execution_method_code,
       fe.executable_name, fa.application_short_name
FROM fnd_concurrent_programs_vl fcp
JOIN fnd_executables fe ON fe.executable_id = fcp.executable_id AND fe.application_id = fcp.executable_application_id
JOIN fnd_application fa ON fa.application_id = fcp.application_id
WHERE fcp.user_concurrent_program_name LIKE '&prog'
   OR fcp.concurrent_program_name LIKE '&prog'
ORDER BY fcp.user_concurrent_program_name
FETCH FIRST 80 ROWS ONLY;""")], extra=apps),
        S("11_executables.sql", "Concurrent executables (spawn, PL/SQL, host, java)",
          "Intermediate",
          "FND_EXECUTABLES — execution_method_code I=PL/SQL, P=Oracle Reports, H=Host, K=Java, etc.",
          [q("Executable lookup",
             "FND_EXECUTABLES_VL.",
             "EXECUTABLE_NAME, EXECUTION_FILE_NAME, METHOD.",
             "Wrong EXECUTION_FILE_NAME after a clone (path still pointing at source).",
             "Host executable path invalid — program stays Running or goes Error immediately.",
             "Fix via the Executable form / $CUSTOM_TOP.",
             "Safe.",
             "APPS",
             """DEFINE exec_p = %XX%

SELECT executable_name, user_executable_name, execution_method_code,
       execution_file_name, execution_file_path, application_id
FROM fnd_executables_vl
WHERE executable_name LIKE '&exec_p'
   OR user_executable_name LIKE '&exec_p'
ORDER BY executable_name;""")], extra=apps),
        S("12_request_groups.sql", "Request groups and program assignments",
          "Intermediate",
          "Why a user cannot submit a program: responsibility → request group → program.",
          [q("Request group contents",
             "FND_REQUEST_GROUPS + FND_REQUEST_GROUP_UNITS.",
             "REQUEST_GROUP_NAME, UNIT_TYPE, PROGRAM.",
             "UNIT_TYPE P=program A=application.",
             "Custom program not in the request group used by the responsibility.",
             "Add via Security > Responsibility > Request. Not SQL insert.",
             "Safe.",
             "APPS",
             """DEFINE rg = %System Administrator%

SELECT rg.request_group_name, rg.application_id,
       rgu.request_unit_type, rgu.unit_application_id,
       fcp.concurrent_program_name, fcp.user_concurrent_program_name
FROM fnd_request_groups rg
JOIN fnd_request_group_units rgu ON rgu.request_group_id = rg.request_group_id
LEFT JOIN fnd_concurrent_programs_vl fcp
       ON fcp.concurrent_program_id = rgu.request_unit_id
      AND rgu.request_unit_type = 'P'
WHERE rg.request_group_name LIKE '&rg'
FETCH FIRST 200 ROWS ONLY;""")], extra=apps),
        S("13_profiles.sql", "Profile option values at site/app/resp/user",
          "Intermediate",
          "FND_PROFILE_OPTIONS + FND_PROFILE_OPTION_VALUES. Classic clone issue: site-level profiles still point at production hosts.",
          [q("Profile values for a name",
             "Join options to values and resolve level.",
             "PROFILE_OPTION_NAME, LEVEL, VALUE.",
             "Levels: 10001 site, 10002 app, 10003 resp, 10004 user (check lookup).",
             "ICX_SESSION_TIMEOUT, apps listener, or outbound mail still at source values after clone.",
             "Change via System Administrator Profiles. Avoid direct UPDATEs.",
             "Safe.",
             "APPS",
             """DEFINE prof = %APPS_DATABASE%

SELECT po.profile_option_name, po.user_profile_option_name,
       DECODE(pov.level_id, 10001,'SITE',10002,'APPLICATION',10003,'RESPONSIBILITY',10004,'USER', TO_CHAR(pov.level_id)) AS lvl,
       pov.profile_option_value,
       pov.level_value
FROM fnd_profile_options_vl po
JOIN fnd_profile_option_values pov ON pov.profile_option_id = po.profile_option_id
WHERE po.profile_option_name LIKE '&prof'
   OR po.user_profile_option_name LIKE '&prof'
ORDER BY po.profile_option_name, pov.level_id;""")], extra=apps),
        S("14_forms.sql", "Forms and form functions",
          "Intermediate",
          "FND_FORM + FND_FORM_FUNCTIONS. Diagnose FRM-40010 / function not found.",
          [q("Form function lookup",
             "Search functions/forms.",
             "FUNCTION_NAME, FORM_NAME, PARAMETERS.",
             "PARAMETERS often include query-only flags.",
             "Function missing after FNDLOAD to a clone.",
             "Reload ldt. Compile form on the apps tier (not SQL).",
             "Safe.",
             "APPS",
             """DEFINE fname = %FNDSCSGN%

SELECT ff.function_name, ff.user_function_name, f.form_name, f.user_form_name, ff.parameters
FROM fnd_form_functions_vl ff
LEFT JOIN fnd_form_vl f ON f.form_id = ff.form_id AND f.application_id = ff.application_id
WHERE ff.function_name LIKE '&fname'
   OR f.form_name LIKE '&fname'
   OR ff.user_function_name LIKE '&fname';""")], extra=apps),
        S("15_packages.sql", "APPS packages invalid or recently changed",
          "Intermediate",
          "APPS owns packages (often wrappers). Invalid APPS packages break concurrent PL/SQL programs.",
          [q("APPS package health",
             "DBA_OBJECTS packages for APPS.",
             "OBJECT_NAME, STATUS, LAST_DDL_TIME.",
             "Mass LAST_DDL after adop compile is expected.",
             "Invalid XX custom packages after a patch overwrote customizations (R12.2 editions / fs).",
             "Use adop compile / adadmin. See 28_EBS_Objects.",
             "Safe.",
             "SELECT on DBA_OBJECTS",
             """SELECT status, COUNT(*) FROM dba_objects
WHERE owner='APPS' AND object_type IN ('PACKAGE','PACKAGE BODY')
GROUP BY status;

SELECT object_type, object_name, last_ddl_time
FROM dba_objects
WHERE owner='APPS' AND status='INVALID'
AND object_type IN ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION')
ORDER BY object_name;""")], extra=apps),
        S("16_invalid_objects.sql", "EBS-relevant invalid objects (product schemas)",
          "Intermediate",
          "Invalids in APPS, APPLSYS, and product schemas. Difference vs 05_Objects/01: filtered to EBS owners.",
          [q("EBS invalids",
             "DBA_OBJECTS for EBS schemas.",
             "OWNER, TYPE, NAME.",
             "A few invalids in unused products may be ignorable; APPS/APPLSYS are not.",
             "Hundreds of invalids after adop abort.",
             "adop phase=fs_clone / compile. Review adop logs.",
             "Safe.",
             "SELECT on DBA_OBJECTS",
             """SELECT owner, object_type, COUNT(*) invalids
FROM dba_objects
WHERE status='INVALID'
AND owner IN ('APPS','APPLSYS','APPS_NE','GL','AR','AP','PO','INV','ONT','HR','PA','XXCUST')
GROUP BY owner, object_type
ORDER BY invalids DESC;

SELECT owner, object_type, object_name FROM dba_objects
WHERE status='INVALID'
AND owner NOT IN ('SYS','SYSTEM','XDB')
ORDER BY owner, object_type, object_name
FETCH FIRST 200 ROWS ONLY;""")], extra=apps),
        S("17_ebs_database_objects.sql", "Object counts for EBS product schemas",
          "Basic",
          "Shape of the EBS database for clone comparison.",
          [q("Counts",
             "DBA_OBJECTS group by owner.",
             "OWNER, TYPE, CNT.",
             "APPS has mostly synonyms/packages. Product schemas have tables.",
             "GL table count far below production after an incomplete export.",
             "Re-import the product schema.",
             "Safe.",
             "SELECT on DBA_OBJECTS",
             """SELECT owner, object_type, COUNT(*) cnt
FROM dba_objects
WHERE owner IN (SELECT oracle_username FROM fnd_oracle_userid)
GROUP BY owner, object_type
ORDER BY owner, object_type;""")], extra=apps),
        S("18_ebs_schema_growth.sql", "EBS schema sizes",
          "Intermediate",
          "DBA_SEGMENTS for FND oracle users. Find which product is growing.",
          [q("Schema GB",
             "Sum segments.",
             "OWNER, GB.",
             "APPLSYS + GL + custom XX often dominate.",
             "One schema jumped vs last month's health check.",
             "19/20 table and index growth.",
             "Safe. Slight dictionary cost.",
             "SELECT on DBA_SEGMENTS",
             """SELECT owner, ROUND(SUM(bytes)/1024/1024/1024,2) gb, COUNT(*) segments
FROM dba_segments
WHERE owner IN (SELECT oracle_username FROM fnd_oracle_userid)
GROUP BY owner
ORDER BY gb DESC;""")], extra=apps),
        S("19_ebs_table_growth.sql", "Largest EBS tables",
          "Intermediate",
          "Top tables in EBS schemas — purge candidates (WF, FND_LOG, interface, audit).",
          [q("Top EBS tables",
             "DBA_SEGMENTS TABLE%.",
             "OWNER, TABLE, GB.",
             "FND_CONCURRENT_REQUESTS, WF_ITEM_ACTIVITY_STATUSES_H, GL_JE_LINES commonly large.",
             "Interface table in top 10.",
             "Purge concurrent requests / workflow / interface with standard EBS purge programs — not TRUNCATE unless approved.",
             "WARNING: No TRUNCATE generated as auto-run.",
             "SELECT on DBA_SEGMENTS",
             """SELECT owner, segment_name, ROUND(bytes/1024/1024/1024,2) gb, tablespace_name
FROM dba_segments
WHERE segment_type LIKE 'TABLE%'
AND owner IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;""")], extra=apps),
        S("20_ebs_index_growth.sql", "Largest EBS indexes",
          "Intermediate",
          "Index space on transactional tables. Rebuild only with a plan.",
          [q("Top EBS indexes",
             "INDEX segments.",
             "OWNER, INDEX, GB.",
             "Indexes larger than the table after mass deletes of requests/workflow.",
             "Huge index on a purged table.",
             "Rebuild ONLINE in a window if fragmentation is proven — change.",
             "Safe to query.",
             "SELECT on DBA_SEGMENTS",
             """SELECT owner, segment_name, ROUND(bytes/1024/1024/1024,2) gb, tablespace_name
FROM dba_segments
WHERE segment_type LIKE 'INDEX%'
AND owner IN (SELECT oracle_username FROM fnd_oracle_userid)
ORDER BY bytes DESC
FETCH FIRST 40 ROWS ONLY;""")], extra=apps),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
