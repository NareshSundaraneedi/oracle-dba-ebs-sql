#!/usr/bin/env python3
"""Recover S() definitions from gen_11_19.py via a tolerant scan and emit SQL."""
import ast
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _writer import Query, Script, write_script

src = Path(__file__).with_name("gen_11_19.py").read_text()

# Split on S( at the start of a call (after whitespace/newline)
parts = re.split(r'\n\s*S\(', src)
print(f"chunks={len(parts)-1}", file=sys.stderr)

ok = 0
fail = 0
for chunk in parts[1:]:
    # Take until we've closed the S( at depth 0 — but source may be broken.
    # Instead, extract the first 5 string literals and the SQL triple-quote.
    strings = []
    # folder, file, purpose, difficulty from leading string literals
    head = chunk[:2500]
    strs = re.findall(r'"((?:[^"\\]|\\.)*)"', head)
    if len(strs) < 5:
        fail += 1
        print("skip head", strs[:3], file=sys.stderr)
        continue
    folder, file_name, purpose, difficulty = strs[0], strs[1], strs[2], strs[3]
    desc = strs[4]
    # title of query is next string after [q(
    qm = re.search(r'\[q\("((?:[^"\\]|\\.)*)"', chunk)
    title = qm.group(1) if qm else purpose
    # remaining q() string args
    qstart = chunk.find("[q(")
    if qstart < 0:
        fail += 1
        continue
    rest = chunk[qstart:]
    qstrs = re.findall(r'"((?:[^"\\]|\\.)*)"', rest[:4000])
    # qstrs[0] is title
    # we need what, columns, interpret, problem, action, caution, privs
    def g(i, default=""):
        return qstrs[i] if len(qstrs) > i else default

    what, columns, interpret, problem, action, caution, privs = (
        g(1), g(2), g(3), g(4), g(5), g(6), g(7)
    )
    sm = re.search(r'"""(.*?)"""', chunk, re.S)
    if not sm:
        fail += 1
        print("no sql", file_name, file=sys.stderr)
        continue
    sql = sm.group(1)
    extra_m = re.search(r'extra="((?:[^"\\]|\\.)*)"', chunk[: sm.end() + 400] if False else chunk)
    # extra often after sql
    extra = ""
    em = re.search(r'extra="((?:[^"\\]|\\.)*)"', chunk)
    if em:
        extra = em.group(1)
    notes = ""
    if "Diagnostics Pack" in extra or "Diagnostics Pack" in (sql or ""):
        notes = extra
    try:
        write_script(
            Script(
                folder=folder,
                file_name=file_name,
                category=folder,
                purpose=purpose,
                difficulty=difficulty,
                production_use="YES",
                description=desc,
                extra_header=extra,
                ebs="R12.2" if "EBS" in extra or folder.startswith("2") else "N/A",
                privileges=privs or "SELECT_CATALOG_ROLE",
                queries=[
                    Query(
                        title=title,
                        sql=sql,
                        what=what,
                        columns=columns,
                        interpret=interpret,
                        problem=problem,
                        action=action,
                        caution=caution,
                        privileges=privs or "SELECT_CATALOG_ROLE",
                        notes=notes,
                    )
                ],
            )
        )
        ok += 1
    except Exception as e:
        fail += 1
        print("err", file_name, e, file=sys.stderr)

print(f"recovered {ok} failed {fail}")
