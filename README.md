# Oracle DBA & Oracle EBS DBA SQL Toolkit

Production-oriented SQL toolkit for **Oracle Database 19c** and **Oracle E-Business Suite R12.2.x**, including RAC, ASM, Data Guard, unified auditing, and EBS concurrent-processing diagnostics.

This is a script library, not an application. There is no installer and no web server. Copy the `Oracle_DBA_SQL_Toolkit` folder to a jump host or DBA workstation and run scripts from SQL\*Plus, SQLcl, or SQL Developer.

---

## What this toolkit is for

Use it when you need the query a production DBA actually runs — not a textbook catalog dump:

- Daily health and capacity checks
- Session, lock, and wait-event incidents
- SQL and AWR/ASH analysis (with license notes)
- Redo, undo, TEMP, memory, RAC, ASM, Data Guard, RMAN
- EBS concurrent managers, requests, workflow, and interfaces
- A 21-step EBS long-running SQL chain (request → session → SQL_ID → plan → wait → blocker → CPU/I/O/TEMP/PGA → action)
- Error playbooks (ORA-01555, 04031, 01652, 00060, 00600/07445, …)

---

## Folder structure

```
Oracle_DBA_SQL_Toolkit/
├── 01_Basic/                              Instance identity, version, size, NLS
├── 02_Database_Administration/            Parameters, FRA, jobs, PDB/CDB
├── 03_Users_Security/                     Users, profiles, grants, failed logins
├── 04_Tablespaces_Datafiles/              Space with 70/85/95 bands
├── 05_Objects/                            Invalids, FKs, unusable indexes
├── 06_Sessions_Processes/                 Sessions, PGA/CPU/I/O, generated kills
├── 07_Performance_Tuning/                 Top SQL, plans, stats, cursors
├── 08_SQL_Tuning/                         Monitor, XPLAN, AWR, ASH (pack notes)
├── 09_Wait_Events/                        Meaning → cause → investigate → fix
├── 10_Locks_Blocking/                     Blocker / blocked / tree / RAC
├── 11_Memory/                             SGA components, PGA, workareas
├── 12_Redo_Archive/                       Redo, switches, archive dests
├── 13_UNDO/                               Undo, 01555, long transactions
├── 14_TEMP/                               TEMP by session/SQL, sort vs hash
├── 15_RAC/                                Services, GC, interconnect, imbalance
├── 16_ASM/                                Diskgroups, rebalance, failure groups
├── 17_DataGuard/                          Lag, MRP/RFS, broker, switchover
├── 18_Backup_Recovery/                    RMAN jobs, recoverability, retention
├── 19_Auditing_Security/                  Unified audit + housekeeping
├── 20_Oracle_EBS/                         Release, FND, programs, growth
├── 21_EBS_Concurrent_Managers/            ICM / Standard / CRM / TM
├── 22_EBS_Concurrent_Requests/            Running, pending, failed, baselines
├── 23_EBS_Workflows/                      Stuck/deferred WF, mailer, background
├── 24_EBS_Interfaces/                     AP AR GL PO INV OM HR PA
├── 25_EBS_Concurrent_SQL_Troubleshooting/ 21-step + master correlation
├── 26_EBS_Performance/                    EBS-scoped SQL, waits, baseline
├── 27_EBS_Users_Responsibilities/         FND users, SoD helpers
├── 28_EBS_Objects/                        APPS/XX invalids and custom
├── 29_EBS_Health_Check/                   OK / WARNING / CRITICAL
├── 30_Advanced_Troubleshooting/           Symptom playbooks
└── 31_Quick_Reference/                    Daily / EBS / perf / incident boards
```

The full catalog is in:

- `Oracle_DBA_SQL_Toolkit/MASTER_INDEX.md` — every script grouped by category
- `SQL_Toolkit_Index.xlsx` — filterable index (Category, Script Name, Purpose, Difficulty, Production Safe, Required Privilege, Oracle Version, EBS)

---

## File naming convention

- Folders are numbered `01_` … `31_` so they sort in the order you work an incident.
- Scripts inside a folder are numbered `01_…sql`, `02_…sql`, … so the intended sequence is obvious (especially folder `25_`).
- Names are lowercase snake_case and describe the check, not a ticket number.
- Similar scripts are *not* duplicates: the header **DESCRIPTION** states when to use this file versus its neighbor (for example V\$SQL cache ranking vs AWR window ranking).

---

## How to use

### SQL\*Plus / SQLcl

```text
sqlplus / as sysdba
-- or, for EBS metadata:
sqlplus apps@EBSPROD

@Oracle_DBA_SQL_Toolkit/31_Quick_Reference/01_DBA_Quick_Reference.sql
@Oracle_DBA_SQL_Toolkit/29_EBS_Health_Check/01_ebs_health_check.sql
```

Substitution variables use SQL\*Plus `DEFINE` (for example `DEFINE request_id = 123456`, `DEFINE hours = 4`, `DEFINE username = SYSADMIN`, `DEFINE program_name = %Gather%`).

On RAC, prefer the `GV$` scripts (already used wherever instance-local views would lie to you).

### Typical workflows

**Morning check**

1. `31_Quick_Reference/01_DBA_Quick_Reference.sql`
2. `31_Quick_Reference/02_EBS_DBA_Quick_Reference.sql` (EBS only)
3. Anything WARNING/CRITICAL → the matching numbered folder

**Database is slow**

1. `31_Quick_Reference/03_Performance_Troubleshooting_Quick_Reference.sql`
2. If blockers → `10_Locks_Blocking/`
3. Else CPU vs wait → `09_Wait_Events/` + `07_Performance_Tuning/`
4. After the fact → `08_SQL_Tuning/` AWR/ASH **if licensed**

**Long-running EBS concurrent request**

1. `25_EBS_Concurrent_SQL_Troubleshooting/21_master_troubleshooting.sql` (`DEFINE request_id`)
2. Follow `recommended_action`
3. Walk `01` … `20` in that folder (request → session → SQL_ID → text → plan → wait → blocker → CPU → logical I/O → physical I/O → TEMP → PGA → I/O → executions → plan history → binds → stats → indexes → growth → manager impact)

**Data Guard / backup / ASM**

Open folders `17_`, `18_`, `16_`. Broker and RMAN commands are printed as `PROMPT` / comments — they are not executed.

---

## Required privileges

| Audience | Typical grant | What you can run |
|---|---|---|
| Production DBA | `SELECT_CATALOG_ROLE` (or targeted `SELECT` on `V_$` / `DBA_` views) | Folders 01–19, 30 (non-EBS), 31 DBA/incident |
| SYS / SYSDBA | OS + SYS | Hidden parameters (`X$`), `utlrp`, datapatch — **not** auto-run here |
| EBS DBA | `APPS` (or a read-only account with APPS synonyms + FND/WF grants) | Folders 20–29, EBS quick reference |
| Audit | `AUDIT_VIEWER` / `AUDIT_ADMIN` | Folder 19 |
| Advisor | `ADVISOR` + Tuning Pack | SQL Tuning Advisor **examples only** |

Least privilege: grant `SELECT` on the specific `V_$` views rather than `SELECT ANY DICTIONARY` where policy requires it.

---

## Production safety guidelines

- **No script automatically kills, drops, truncates, deletes, purges, or compiles SYS.**
- Destructive SQL is either:
  - **generated** as text (`SELECT 'ALTER SYSTEM KILL SESSION …'`) with `WHERE 1 = 0` until you edit it, or
  - shown as a **commented example** with `WARNING`.
- `ALTER SYSTEM KILL SESSION` / `DISCONNECT SESSION` must include `@inst_id` on RAC. Prefer `DISCONNECT … POST_TRANSACTION` for inactive lock holders.
- EBS product schema passwords: use **AFPASSWD / FNDCPASS** (MOS), never casual `ALTER USER APPS IDENTIFIED BY`.
- Do **not** flush the shared pool, bounce the instance, or gather schema stats as a first response to slowness.
- Do **not** `DELETE`/`TRUNCATE` interface or workflow tables. Use the standard EBS import/purge programs.
- Unified audit purge (`DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL`) is a **compliance** change — export to SIEM first.
- Confirm `DB_UNIQUE_NAME` and `DATABASE_ROLE` before any generated command (clones and standbys share `DB_NAME`).

---

## Oracle 19c compatibility

- Views used are 19c current: `V$`, `GV$`, `DBA_*`, `CDB_*` / `V$PDBS` (no-op on non-CDB), `DBA_REGISTRY_SQLPATCH`, `DBA_INDEX_USAGE`, `UNIFIED_AUDIT_TRAIL`, `V$RMAN_BACKUP_JOB_DETAILS`.
- Deprecated 8i/9i favorites (`V$PARAMETER2` still exists but we use `V$PARAMETER` / `V$SPPARAMETER`; traditional `AUD$` is only mentioned for mixed-mode upgrades).
- `FETCH FIRST n ROWS ONLY` is used instead of `ROWNUM` wrappers where a limit is needed (except a few existence checks).
- PDB/CDB scripts are safe on non-CDB EBS databases (they return no PDB rows).

---

## EBS R12.2 compatibility

- Metadata: `FND_*`, `AD_*`, `WF_*`, `FND_SVC_COMPONENTS` (OAM service components / mailer / listeners).
- Concurrent processing: `FND_CONCURRENT_REQUESTS`, `FND_CONCURRENT_QUEUES_VL`, `FND_CONCURRENT_PROCESSES`, specialization (`FND_CONCURRENT_QUEUE_CONTENT`), work shifts (`FND_CONCURRENT_QUEUE_SIZE`).
- Phase/status: `P` pending, `R` running, `C` complete; status `Q` standby, `E` error, `G` warning, `X` terminated, `C` normal (complete).
- Interfaces covered: AP, AR Autoinvoice, GL, PO, INV (`MTL_TRANSACTIONS_INTERFACE`), OM, HR API transactions, Projects.
- R12.2 dualfs / editions: compile via **adop / adadmin**, not ad-hoc `ALTER PACKAGE` on APPS during peak.
- Scripts that query `FND_%` fail on a non-EBS database — that is expected.

---

## Licensing considerations

| Feature | Pack / option | Scripts |
|---|---|---|
| `V$SQL`, `V$SESSION`, `V$SQL_PLAN`, `DBMS_XPLAN.DISPLAY_CURSOR` | Database (no Diag/Tuning pack) | Most of 06, 07, 09, 10, 25 |
| `V$ACTIVE_SESSION_HISTORY`, `DBA_HIST_*`, `awrrpt.sql` | **Diagnostics Pack** | Many files in `08_SQL_Tuning`, some growth/plan-history scripts |
| `V$SQL_MONITOR`, SQL Tuning Advisor, `ACCEPT_SQL_PROFILE` | **Tuning Pack** | `08_SQL_Tuning/01`, `04`, `05` |
| SQL plan baselines | Enterprise Edition | `08_SQL_Tuning/06` |
| Unified audit | 19c feature | Folder 19 |
| Fine Grained Auditing | Enterprise Edition | `19/13` |
| In-Memory, Vault, Privilege Analysis | Separate options | Called out in-file |

If you are **not** licensed for Diagnostics/Tuning Pack, stay on `V$` / `GV$` / `DBA_*` scripts. Pack-dependent files say so in the header.

This toolkit is **not** a license audit. `DBA_FEATURE_USAGE_STATISTICS` is informational only.

---

## Troubleshooting workflow (cheat sheet)

```
Confirm environment (01_Basic / 31 incident board)
        ↓
Is it down or restricted?  → instance, listener (OS), archive dest, FRA
        ↓
Are sessions blocked?      → 10_Locks_Blocking (root blocker only)
        ↓
CPU-bound or wait-bound?   → 09_Wait_Events/04 then the #1 event file
        ↓
Which SQL / request?       → 07 or 25 (EBS) or 08 AWR (licensed)
        ↓
Plan / binds / stats / TEMP / PGA / undo
        ↓
Change in a window, then post-fix validation (same script as evidence)
```

Each `30_Advanced_Troubleshooting` file follows:

**Symptom → Initial checks → SQL → Evidence to collect → Root causes → Fix → Post-fix validation**

---

## Space warning bands

Used on tablespaces, FRA, TEMP, ASM usable space, and process/session limits:

| Used | Level |
|---|---|
| < 70% | NORMAL |
| 70–85% | MONITOR |
| 85–95% | WARNING |
| > 95% | CRITICAL |

Autoextend files are judged against **MAXSIZE**, not current file size, so a 90% allocated file that can still grow is not treated the same as a file already at MAXSIZE.

---

## Regenerating the toolkit (optional)

Python helpers under `tools/` generate the `.sql` files and the Excel index. You do not need them to *use* the SQL.

```text
python3 tools/gen_01_basic.py
# … other gen_*.py …
python3 tools/build_index.py
```

---

## Disclaimer

Queries are intended for experienced Oracle and EBS DBAs. Test in a non-production clone when the script is new to your site. Object names for optional packs/components may be absent (`ORA-00942`) — skip that statement. Concurrent-manager `CONTROL_CODE` / transaction-manager type codes can vary slightly by AD/TXK level; confirm against your site if a filter looks empty.
