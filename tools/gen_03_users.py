#!/usr/bin/env python3
from _writer import Query, Script, write_many


def scripts():
    return [
        Script(
            folder="03_Users_Security",
            file_name="01_list_users.sql",
            category="03_Users_Security",
            purpose="List all database users with default tablespace and profile",
            difficulty="Basic",
            production_use="YES",
            description="""Inventory of DBA_USERS. On EBS this includes product schemas (GL, AR,
APPS, APPLSYS) plus named application users if they have DB accounts.
Most EBS end users are FND_USER rows, not database users.""",
            queries=[
                Query(
                    title="All database users",
                    what="Reads DBA_USERS.",
                    columns="USERNAME, ACCOUNT_STATUS, CREATED, PROFILE, DEFAULT_TABLESPACE, AUTHENTICATION_TYPE.",
                    interpret="AUTHENTICATION_TYPE PASSWORD vs EXTERNAL vs NONE. EBS product schemas should remain LOCKED except APPS/APPLSYS/etc. that must be open.",
                    problem="Unexpected OPEN users created outside change control. Default tablespace SYSTEM.",
                    action="Lock unused accounts with approval. Do not drop users from this script.",
                    caution="Safe. EBS schema passwords are tightly controlled — do not reset them here.",
                    privileges="SELECT on DBA_USERS",
                    ebs="Useful for EBS",
                    sql="""SELECT
       username,
       user_id,
       account_status,
       lock_date,
       expiry_date,
       created,
       profile,
       default_tablespace,
       temporary_tablespace,
       authentication_type,
       oracle_maintained,
       common
FROM   dba_users
ORDER BY username;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="02_user_status.sql",
            category="03_Users_Security",
            purpose="Count users by account status",
            difficulty="Basic",
            production_use="YES",
            description="""Roll-up of ACCOUNT_STATUS. Use after a security sweep or clone to
confirm which accounts are OPEN.""",
            queries=[
                Query(
                    title="Account status summary",
                    what="Groups DBA_USERS by ACCOUNT_STATUS.",
                    columns="ACCOUNT_STATUS, USER_COUNT.",
                    interpret="OPEN should be a short, known list on a hardened production database.",
                    problem="Many OPEN accounts after a refresh from production to a lower environment without re-locking.",
                    action="Compare to the approved open-account baseline.",
                    caution="Safe.",
                    privileges="SELECT on DBA_USERS",
                    sql="""SELECT account_status, COUNT(*) AS user_count
FROM   dba_users
GROUP BY account_status
ORDER BY user_count DESC;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="03_locked_users.sql",
            category="03_Users_Security",
            purpose="List locked accounts and lock dates",
            difficulty="Basic",
            production_use="YES",
            description="""Shows locked users. Distinguish administrative locks from
FAILED_LOGIN locks (LOCKED(TIMED)).""",
            queries=[
                Query(
                    title="Locked users",
                    what="Filters DBA_USERS for lock statuses.",
                    columns="USERNAME, ACCOUNT_STATUS, LOCK_DATE, PROFILE.",
                    interpret="LOCKED(TIMED) is usually failed-login lockout and may expire. LOCKED is an explicit lock.",
                    problem="APPS or a batch schema unexpectedly LOCKED — EBS will fail immediately.",
                    action="If a required schema is locked, unlock only with approval: ALTER USER x ACCOUNT UNLOCK; — generated, not executed.",
                    caution="WARNING: Unlock is a security-sensitive change. Generated only.",
                    privileges="SELECT on DBA_USERS",
                    sql="""SELECT
       username,
       account_status,
       lock_date,
       expiry_date,
       profile,
       oracle_maintained
FROM   dba_users
WHERE  account_status LIKE '%LOCK%'
ORDER BY lock_date DESC NULLS LAST, username;

-- WARNING: Review carefully before executing.
SELECT 'ALTER USER "' || username || '" ACCOUNT UNLOCK;' AS unlock_cmd
FROM   dba_users
WHERE  account_status LIKE '%LOCK%'
AND    oracle_maintained = 'N';""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="04_expired_users.sql",
            category="03_Users_Security",
            purpose="List expired and expired-grace accounts",
            difficulty="Basic",
            production_use="YES",
            description="""Password expiry on APPS/APPLSYS/SYSADMIN-related schemas is a
self-inflicted EBS outage. Catch it before the grace period ends.""",
            queries=[
                Query(
                    title="Expired and grace users",
                    what="Filters DBA_USERS for EXPIRED statuses.",
                    columns="USERNAME, ACCOUNT_STATUS, EXPIRY_DATE, PROFILE.",
                    interpret="EXPIRED(GRACE) can still log in but will be prompted to change password — batch accounts cannot do that.",
                    problem="APPS in EXPIRED(GRACE) — concurrent managers will start failing as connections recycle.",
                    action="For service accounts, use a profile with PASSWORD_LIFE_TIME UNLIMITED. Password changes for EBS schemas follow Oracle EBS documentation only.",
                    caution="Never expire or reset EBS product schema passwords with generic ALTER USER without the official supported method.",
                    privileges="SELECT on DBA_USERS",
                    ebs="Critical for EBS",
                    sql="""SELECT
       username,
       account_status,
       expiry_date,
       profile,
       default_tablespace
FROM   dba_users
WHERE  account_status LIKE '%EXPIRED%'
ORDER BY expiry_date, username;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="05_password_expiry.sql",
            category="03_Users_Security",
            purpose="Forecast password expiry for OPEN accounts",
            difficulty="Intermediate",
            production_use="YES",
            description="""Shows days until EXPIRY_DATE for OPEN users so you can act before
batch accounts lock out.""",
            queries=[
                Query(
                    title="Days until password expiry",
                    what="Computes EXPIRY_DATE - SYSDATE for OPEN users with an expiry.",
                    columns="USERNAME, EXPIRY_DATE, DAYS_LEFT, PROFILE.",
                    interpret="NULL expiry means UNLIMITED life time or non-password auth.",
                    problem="DAYS_LEFT < 14 for a service account.",
                    action="Adjust profile or rotate the password in a planned change. EBS schemas: follow MOS password-change notes.",
                    caution="Safe.",
                    privileges="SELECT on DBA_USERS",
                    sql="""SELECT
       username,
       account_status,
       profile,
       expiry_date,
       ROUND(expiry_date - SYSDATE) AS days_left,
       CASE
         WHEN expiry_date IS NULL THEN 'NO_EXPIRY'
         WHEN expiry_date - SYSDATE < 0 THEN 'EXPIRED'
         WHEN expiry_date - SYSDATE < 7 THEN 'CRITICAL'
         WHEN expiry_date - SYSDATE < 14 THEN 'WARNING'
         WHEN expiry_date - SYSDATE < 30 THEN 'MONITOR'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_users
WHERE  account_status = 'OPEN'
ORDER BY expiry_date NULLS LAST, username;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="06_profile_information.sql",
            category="03_Users_Security",
            purpose="List profiles and resource/password limits",
            difficulty="Intermediate",
            production_use="YES",
            description="""Profiles control failed-login lockout, password life, and idle time.
A too-aggressive DEFAULT profile locks EBS batch users.""",
            queries=[
                Query(
                    title="Profile limits and user counts",
                    what="Reads DBA_PROFILES and counts users per profile.",
                    columns="PROFILE, RESOURCE_NAME, LIMIT, USER_COUNT.",
                    interpret="FAILED_LOGIN_ATTEMPTS UNLIMITED is weak. PASSWORD_LIFE_TIME 60 on APPS is dangerous.",
                    problem="IDLE_TIME set on application users causing random disconnects. FAILED_LOGIN_ATTEMPTS 3 on shared batch accounts.",
                    action="Create a dedicated profile for service accounts. Do not ALTER PROFILE in production without approval.",
                    caution="Safe to query.",
                    privileges="SELECT on DBA_PROFILES, DBA_USERS",
                    sql="""SELECT profile, resource_type, resource_name, limit
FROM   dba_profiles
ORDER BY profile, resource_type, resource_name;

SELECT profile, COUNT(*) AS user_count
FROM   dba_users
GROUP BY profile
ORDER BY user_count DESC;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="07_user_creation_date.sql",
            category="03_Users_Security",
            purpose="Show recently created database users",
            difficulty="Basic",
            production_use="YES",
            description="""Detects accounts created outside change control — a common audit finding.""",
            queries=[
                Query(
                    title="Users created in the last 90 days",
                    what="Filters DBA_USERS by CREATED.",
                    columns="USERNAME, CREATED, ACCOUNT_STATUS, ORACLE_MAINTAINED.",
                    interpret="ORACLE_MAINTAINED Y users created recently usually mean a component install, not a human account.",
                    problem="An OPEN user created last night with DBA role (check 12_system_privileges.sql).",
                    action="Validate against the change ticket. Lock if unauthorized.",
                    caution="Safe.",
                    privileges="SELECT on DBA_USERS",
                    sql="""SELECT
       username,
       created,
       account_status,
       profile,
       oracle_maintained,
       common
FROM   dba_users
WHERE  created > SYSDATE - 90
ORDER BY created DESC;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="08_last_login.sql",
            category="03_Users_Security",
            purpose="Show last login time (12c+ DBA_USERS.LAST_LOGIN)",
            difficulty="Intermediate",
            production_use="YES",
            description="""LAST_LOGIN is populated when the initialization parameter
MAX_IDLE_TIME related tracking / 12.1+ last login feature is available.
On 19c it is in DBA_USERS.""",
            queries=[
                Query(
                    title="Last login for non-Oracle-maintained users",
                    what="Reads DBA_USERS.LAST_LOGIN (12.1+).",
                    columns="USERNAME, LAST_LOGIN, ACCOUNT_STATUS.",
                    interpret="NULL last login can mean the account has never logged in since the feature was available, or is used only via proxy.",
                    problem="Interactive DBA accounts unused for 180+ days still OPEN.",
                    action="Lock stale named accounts after owner confirmation.",
                    caution="Safe. LAST_LOGIN requires Oracle 12.1+ (present on 19c).",
                    privileges="SELECT on DBA_USERS",
                    notes="Oracle 19c (LAST_LOGIN column).",
                    sql="""SELECT
       username,
       last_login,
       account_status,
       created,
       profile
FROM   dba_users
WHERE  oracle_maintained = 'N'
ORDER BY last_login DESC NULLS LAST;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="09_default_tablespace.sql",
            category="03_Users_Security",
            purpose="Find users whose default tablespace is SYSTEM or SYSAUX",
            difficulty="Basic",
            production_use="YES",
            description="""Application users must not default to SYSTEM. Space and recovery
impact if they create objects there.""",
            queries=[
                Query(
                    title="Default tablespace assignment",
                    what="Groups users by default tablespace and flags SYSTEM/SYSAUX.",
                    columns="USERNAME, DEFAULT_TABLESPACE, TEMPORARY_TABLESPACE.",
                    interpret="Only SYS should normally use SYSTEM as default.",
                    problem="APPS or custom user defaulting to SYSTEM.",
                    action="ALTER USER x DEFAULT TABLESPACE <correct> — generated only.",
                    caution="WARNING: ALTER USER is a change. Generated only.",
                    privileges="SELECT on DBA_USERS",
                    sql="""SELECT
       username,
       default_tablespace,
       temporary_tablespace,
       account_status,
       CASE
         WHEN default_tablespace IN ('SYSTEM','SYSAUX') AND username NOT IN ('SYS','SYSTEM') THEN 'WARNING'
         ELSE 'NORMAL'
       END AS alert_level
FROM   dba_users
ORDER BY default_tablespace, username;

-- WARNING: Review carefully before executing.
SELECT 'ALTER USER "' || username || '" DEFAULT TABLESPACE USERS;' AS fix_cmd
FROM   dba_users
WHERE  default_tablespace IN ('SYSTEM','SYSAUX')
AND    username NOT IN ('SYS','SYSTEM');""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="10_temporary_tablespace.sql",
            category="03_Users_Security",
            purpose="Show temporary tablespace assigned to each user",
            difficulty="Basic",
            production_use="YES",
            description="""Wrong TEMP assignment (for example SYSTEM) causes temp contention
and ORA-01652 in unexpected files.""",
            queries=[
                Query(
                    title="Temporary tablespace per user",
                    what="Reads DBA_USERS.TEMPORARY_TABLESPACE.",
                    columns="USERNAME, TEMPORARY_TABLESPACE.",
                    interpret="Most users should share the default TEMP. Power users sometimes get a dedicated TEMP.",
                    problem="TEMPORARY_TABLESPACE = SYSTEM or a tablespace that is not TEMPORARY contents.",
                    action="ALTER USER x TEMPORARY TABLESPACE TEMP — generated only.",
                    caution="WARNING: ALTER USER generated only.",
                    privileges="SELECT on DBA_USERS, DBA_TABLESPACES",
                    sql="""SELECT
       u.username,
       u.temporary_tablespace,
       t.contents,
       t.status
FROM   dba_users u
LEFT JOIN dba_tablespaces t
       ON t.tablespace_name = u.temporary_tablespace
ORDER BY u.temporary_tablespace, u.username;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="11_roles.sql",
            category="03_Users_Security",
            purpose="List roles and role grants to users",
            difficulty="Intermediate",
            production_use="YES",
            description="""Shows DBA_ROLES and DBA_ROLE_PRIVS. DBA, SYSDBA-equivalent roles
on named users are a critical finding.""",
            queries=[
                Query(
                    title="Roles and who has them",
                    what="Reads DBA_ROLES and DBA_ROLE_PRIVS.",
                    columns="ROLE, GRANTEE, ADMIN_OPTION, DEFAULT_ROLE.",
                    interpret="ADMIN_OPTION YES means the grantee can grant the role onward.",
                    problem="DBA granted to an application user or PUBLIC.",
                    action="Revoke after impact analysis. Generated revoke only.",
                    caution="WARNING: REVOKE is destructive to privileges. Generated only.",
                    privileges="SELECT on DBA_ROLES, DBA_ROLE_PRIVS",
                    sql="""SELECT role, authentication_type, common, oracle_maintained
FROM   dba_roles
ORDER BY role;

SELECT grantee, granted_role, admin_option, delegate_option, default_role, common
FROM   dba_role_privs
WHERE  granted_role IN ('DBA','SYSDBA','DATAPUMP_IMP_FULL_DATABASE','IMP_FULL_DATABASE','EXP_FULL_DATABASE','SELECT_CATALOG_ROLE')
OR     grantee NOT IN (SELECT role FROM dba_roles)
ORDER BY granted_role, grantee;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="12_system_privileges.sql",
            category="03_Users_Security",
            purpose="List powerful system privileges",
            difficulty="Intermediate",
            production_use="YES",
            description="""Focuses on dangerous privileges: ANY, DBA-like, GRANT ANY, ALTER USER.""",
            queries=[
                Query(
                    title="High-risk system privileges",
                    what="Filters DBA_SYS_PRIVS for ANY / ADMIN / GRANT privileges.",
                    columns="GRANTEE, PRIVILEGE, ADMIN_OPTION.",
                    interpret="ANY privileges bypass schema isolation. PUBLIC should have almost none.",
                    problem="GRANT ANY PRIVILEGE or SELECT ANY TABLE on an app user.",
                    action="Revoke after confirming nothing depends on it. Generated only.",
                    caution="WARNING: REVOKE generated only.",
                    privileges="SELECT on DBA_SYS_PRIVS",
                    sql="""SELECT
       grantee,
       privilege,
       admin_option,
       common
FROM   dba_sys_privs
WHERE  privilege LIKE '%ANY%'
OR     privilege IN ('GRANT ANY PRIVILEGE','GRANT ANY ROLE','GRANT ANY OBJECT PRIVILEGE',
                     'ALTER USER','DROP USER','BECOME USER','ALTER SYSTEM','ALTER DATABASE',
                     'EXEMPT ACCESS POLICY','EXEMPT REDACTION POLICY')
ORDER BY privilege, grantee;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="13_object_privileges.sql",
            category="03_Users_Security",
            purpose="List object grants for a schema or grantee",
            difficulty="Intermediate",
            production_use="YES",
            description="""Parameterized object privilege search. Use for APPS grants and
custom XX users.""",
            queries=[
                Query(
                    title="Object privileges filtered by owner or grantee",
                    what="Reads DBA_TAB_PRIVS with bind/substitution filters.",
                    columns="GRANTEE, OWNER, TABLE_NAME, PRIVILEGE, GRANTABLE.",
                    interpret="GRANTABLE YES means the grantee can pass the privilege on.",
                    problem="PUBLIC SELECT on a table with PII. Unexpected DELETE on a setup table.",
                    action="Revoke after impact analysis. Generated only.",
                    caution="Result set can be huge on EBS. Always filter.",
                    privileges="SELECT on DBA_TAB_PRIVS",
                    ebs="Useful for EBS",
                    sql="""-- Set one or both filters
DEFINE grantee_p = APPS
DEFINE owner_p   = GL

SELECT
       grantee,
       owner,
       table_name,
       privilege,
       grantable,
       type
FROM   dba_tab_privs
WHERE  (grantee = '&grantee_p' OR '&grantee_p' IS NULL)
AND    (owner = '&owner_p' OR '&owner_p' IS NULL)
AND    ROWNUM <= 500
ORDER BY owner, table_name, grantee, privilege;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="14_role_privileges.sql",
            category="03_Users_Security",
            purpose="Expand privileges a role conveys",
            difficulty="Intermediate",
            production_use="YES",
            description="""Shows system and object privileges granted to a role, plus nested roles.""",
            queries=[
                Query(
                    title="Privileges granted to a role",
                    what="Reads ROLE_SYS_PRIVS, ROLE_TAB_PRIVS, ROLE_ROLE_PRIVS.",
                    columns="ROLE, PRIVILEGE, OWNER, TABLE_NAME, GRANTED_ROLE.",
                    interpret="Nested roles hide DBA-like access. Expand fully before certifying a user.",
                    problem="A 'read only' role that includes UPDATE via a nested role.",
                    action="Rebuild the role with least privilege.",
                    caution="Safe.",
                    privileges="SELECT on ROLE_SYS_PRIVS, ROLE_TAB_PRIVS, ROLE_ROLE_PRIVS",
                    sql="""DEFINE role_p = DBA

SELECT role, privilege, admin_option
FROM   role_sys_privs
WHERE  role = '&role_p'
ORDER BY privilege;

SELECT role, owner, table_name, column_name, privilege, grantable
FROM   role_tab_privs
WHERE  role = '&role_p'
AND    ROWNUM <= 200
ORDER BY owner, table_name;

SELECT role, granted_role, admin_option
FROM   role_role_privs
WHERE  role = '&role_p'
ORDER BY granted_role;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="15_grants.sql",
            category="03_Users_Security",
            purpose="Show all privilege paths for one user (roles + direct grants)",
            difficulty="Intermediate",
            production_use="YES",
            description="""Single-user privilege dump used during joiner/mover/leaver reviews.""",
            queries=[
                Query(
                    title="Direct grants and granted roles for one user",
                    what="Combines DBA_SYS_PRIVS, DBA_TAB_PRIVS, DBA_ROLE_PRIVS for a username.",
                    columns="PRIV_TYPE, PRIVILEGE, OWNER, TABLE_NAME.",
                    interpret="This is one level deep. Recurse roles with 14_role_privileges.sql.",
                    problem="User has both an application role and DBA.",
                    action="Revoke excess after approval.",
                    caution="Safe.",
                    privileges="SELECT on DBA_SYS_PRIVS, DBA_TAB_PRIVS, DBA_ROLE_PRIVS",
                    sql="""DEFINE uname = SCOTT

SELECT 'SYS' AS priv_type, privilege, TO_CHAR(NULL) AS owner, TO_CHAR(NULL) AS table_name, admin_option AS extra
FROM   dba_sys_privs
WHERE  grantee = '&uname'
UNION ALL
SELECT 'TAB', privilege, owner, table_name, grantable
FROM   dba_tab_privs
WHERE  grantee = '&uname'
UNION ALL
SELECT 'ROLE', granted_role, NULL, NULL, admin_option
FROM   dba_role_privs
WHERE  grantee = '&uname'
ORDER BY 1, 2;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="16_proxy_users.sql",
            category="03_Users_Security",
            purpose="List proxy user relationships",
            difficulty="Intermediate",
            production_use="YES",
            description="""Proxy authentication (ALTER USER x GRANT CONNECT THROUGH y) is used
by some middle tiers and OEM. Unexpected proxies are a security finding.""",
            queries=[
                Query(
                    title="Proxy users",
                    what="Reads PROXY_USERS (or DBA_PROXIES on some versions — PROXY_USERS is the 11g+ data dictionary view).",
                    columns="PROXY, CLIENT, AUTHENTICATION, FLAGS.",
                    interpret="PROXY is the middle-tier account. CLIENT is the end-user schema it can connect as.",
                    problem="A widely privileged proxy that can become APPS.",
                    action="Revoke CONNECT THROUGH after confirming the app does not need it.",
                    caution="Safe to query.",
                    privileges="SELECT on PROXY_USERS",
                    sql="""SELECT proxy, client, authentication, flags
FROM   proxy_users
ORDER BY proxy, client;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="17_failed_logins.sql",
            category="03_Users_Security",
            purpose="Investigate failed logins from unified audit or DBA_USERS lock state",
            difficulty="Advanced",
            production_use="YES",
            description="""Failed logins appear in UNIFIED_AUDIT_TRAIL when unified auditing
is enabled (default-on in fresh 19c installs; mixed-mode possible on
upgrades). Also infer from LOCKED(TIMED).""",
            extra_header="If unified auditing is not enabled, traditional AUD$ / DBA_AUDIT_TRAIL may still be used.",
            queries=[
                Query(
                    title="Recent failed logins (unified audit)",
                    what="Queries UNIFIED_AUDIT_TRAIL for return code 1017 / action LOGON failures.",
                    columns="EVENT_TIMESTAMP, DBUSERNAME, USERHOST, RETURN_CODE, OS_USERNAME.",
                    interpret="ORA-1017 storms from one USERHOST often mean a bad password in a config file after a rotation.",
                    problem="Hundreds of failures then LOCKED(TIMED) on APPS.",
                    action="Fix the client credential. Unlock with approval. Do not disable the profile lockout.",
                    caution="UNIFIED_AUDIT_TRAIL can be large — bounded by time. Diagnostics of audit data is licensed as part of the database; Fine Grained Auditing is EE.",
                    privileges="AUDIT_ADMIN or SELECT on UNIFIED_AUDIT_TRAIL / AUDSYS",
                    notes="Oracle 19c unified auditing. May return no rows if unified audit is not enabled.",
                    sql="""SELECT
       username,
       account_status,
       lock_date
FROM   dba_users
WHERE  account_status LIKE 'LOCKED%';

-- Unified audit (19c). Bound the time window.
SELECT
       event_timestamp,
       dbusername,
       userhost,
       os_username,
       terminal,
       return_code,
       unified_audit_policies
FROM   unified_audit_trail
WHERE  event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
AND    (return_code IN (1017, 28000, 28001) OR action_name = 'LOGON')
AND    return_code <> 0
AND    ROWNUM <= 500
ORDER BY event_timestamp DESC;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="18_password_policies.sql",
            category="03_Users_Security",
            purpose="Extract password-related profile limits",
            difficulty="Intermediate",
            production_use="YES",
            description="""Password complexity, reuse, and life-time settings per profile.""",
            queries=[
                Query(
                    title="Password resource limits",
                    what="Filters DBA_PROFILES for PASSWORD% and FAILED_LOGIN.",
                    columns="PROFILE, RESOURCE_NAME, LIMIT.",
                    interpret="PASSWORD_VERIFY_FUNCTION NULL means no complexity function.",
                    problem="DEFAULT profile UNLIMITED everywhere on a production database subject to audit.",
                    action="Align profiles with the security standard. Service accounts get a dedicated profile.",
                    caution="Safe.",
                    privileges="SELECT on DBA_PROFILES",
                    sql="""SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  resource_name LIKE 'PASSWORD%'
OR     resource_name = 'FAILED_LOGIN_ATTEMPTS'
ORDER BY profile, resource_name;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="19_privilege_analysis.sql",
            category="03_Users_Security",
            purpose="Show privilege analysis captures (12c+ Privilege Analysis)",
            difficulty="Advanced",
            production_use="YES",
            description="""Privilege Analysis (Database Vault option / 12c feature) records used
vs unused privileges. This script only lists existing captures — it
does not start a capture (that is a change and may require the option).""",
            extra_header="Privilege Analysis historically required Database Vault. Check your license before enabling captures.",
            queries=[
                Query(
                    title="Privilege analysis runs",
                    what="Reads DBA_PRIV_CAPTURES if the view exists.",
                    columns="NAME, TYPE, ENABLED, ROLES.",
                    interpret="No rows may mean the feature was never used or the view is not present.",
                    problem="A capture left ENABLED in production adding overhead.",
                    action="Disable leftover captures after exporting results.",
                    caution="Safe to query. Enabling captures is a licensed change.",
                    privileges="SELECT on DBA_PRIV_CAPTURES",
                    notes="Optional component. Script handles missing view via a existence check comment.",
                    sql="""-- If ORA-00942, Privilege Analysis views are not installed — skip.
SELECT name, type, enabled, roles
FROM   dba_priv_captures
ORDER BY name;

SELECT capture, username, used_role, used_sys_priv
FROM   dba_used_sysprivs
WHERE  ROWNUM <= 200;""",
                )
            ],
        ),
        Script(
            folder="03_Users_Security",
            file_name="20_security_checks.sql",
            category="03_Users_Security",
            purpose="Packaged security hygiene checks for a production database",
            difficulty="Advanced",
            production_use="YES",
            description="""A short checklist: default passwords (where detectable), PUBLIC
dangerous grants, users with DBA, and remote_os_authent.""",
            queries=[
                Query(
                    title="High-value security findings",
                    what="Several small queries that flag common production issues.",
                    columns="FINDING, DETAIL.",
                    interpret="Each row is a finding to review, not automatically a vulnerability.",
                    problem="ANY of: DBA on non-DBA named users, PUBLIC UTL_FILE, remote_os_authent TRUE.",
                    action="Remediate via change control. Do not revoke PUBLIC grants blindly on EBS — APPS depends on many of them.",
                    caution="EBS requires specific PUBLIC and APPS grants. Compare against a known-good EBS baseline before revoking.",
                    privileges="SELECT on DBA_ROLE_PRIVS, DBA_TAB_PRIVS, DBA_USERS, V_$PARAMETER",
                    ebs="Review carefully on EBS",
                    sql="""SELECT 'DBA_ROLE' AS finding, grantee AS detail
FROM   dba_role_privs
WHERE  granted_role = 'DBA'
AND    grantee NOT IN ('SYS','SYSTEM')
UNION ALL
SELECT 'PUBLIC_UTL', table_name || ' ' || privilege
FROM   dba_tab_privs
WHERE  grantee = 'PUBLIC'
AND    table_name IN ('UTL_FILE','UTL_HTTP','UTL_SMTP','UTL_TCP','DBMS_JAVA','DBMS_SCHEDULER')
UNION ALL
SELECT 'PARAM', name || '=' || value
FROM   v$parameter
WHERE  name IN ('remote_os_authent','os_authent_prefix','sec_case_sensitive_logon','audit_trail','unified_audit_systemlog')
UNION ALL
SELECT 'OPEN_ORACLE_MAINTAINED', username
FROM   dba_users
WHERE  oracle_maintained = 'Y'
AND    account_status = 'OPEN'
AND    username NOT IN ('SYS','SYSTEM','AUDSYS','GSMUSER','DBSFWUSER','REMOTE_SCHEDULER_AGENT','SYSRAC','SYSBACKUP','SYSDG','SYSKM')
ORDER BY 1, 2;""",
                )
            ],
        ),
    ]


if __name__ == "__main__":
    print(write_many(scripts()))
