#!/usr/bin/env python3
"""Shared writer for Oracle DBA SQL Toolkit files."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Iterable


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Oracle_DBA_SQL_Toolkit"))

INDEX_ROWS: list[dict] = []


@dataclass
class Query:
    title: str
    sql: str
    what: str
    columns: str
    interpret: str
    problem: str
    action: str
    caution: str
    privileges: str
    notes: str = ""
    ebs: str = ""


@dataclass
class Script:
    folder: str
    file_name: str
    category: str
    purpose: str
    difficulty: str
    production_use: str
    description: str
    queries: list[Query]
    ebs: str = "N/A"
    privileges: str = "SELECT_CATALOG_ROLE"
    oracle_version: str = "19c"
    ebs_version: str = "R12.2.x where applicable"
    extra_header: str = ""


def write_script(script: Script) -> str:
    folder = os.path.join(ROOT, script.folder)
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, script.file_name)

    lines: list[str] = []
    lines.append("-" * 80)
    lines.append(f"-- File Name       : {script.file_name}")
    lines.append(f"-- Category        : {script.category}")
    lines.append(f"-- Purpose         : {script.purpose}")
    lines.append(f"-- Oracle Version  : {script.oracle_version}")
    lines.append(f"-- EBS Version     : {script.ebs_version}")
    lines.append(f"-- Difficulty      : {script.difficulty}")
    lines.append(f"-- Production Use  : {script.production_use}")
    lines.append("-" * 80)
    lines.append("-- DESCRIPTION")
    for para in script.description.strip().split("\n"):
        lines.append(f"-- {para}" if para.strip() else "--")
    if script.extra_header:
        lines.append("--")
        for para in script.extra_header.strip().split("\n"):
            lines.append(f"-- {para}" if para.strip() else "--")
    lines.append("-" * 80)
    lines.append("SET LINESIZE 300")
    lines.append("SET PAGESIZE 100")
    lines.append("SET TRIMSPOOL ON")
    lines.append("SET TAB OFF")
    lines.append("SET VERIFY OFF")
    lines.append("COLUMN status FORMAT A20")
    lines.append("")

    for i, q in enumerate(script.queries, 1):
        lines.append("-" * 80)
        lines.append(f"-- QUERY {i}: {q.title}")
        lines.append("-" * 80)
        lines.append(f"-- 1. What the query does")
        lines.append(f"--    {q.what}")
        lines.append(f"-- 2. Important columns")
        lines.append(f"--    {q.columns}")
        lines.append(f"-- 3. How to interpret the output")
        lines.append(f"--    {q.interpret}")
        lines.append(f"-- 4. What indicates a problem")
        lines.append(f"--    {q.problem}")
        lines.append(f"-- 5. Recommended DBA action")
        lines.append(f"--    {q.action}")
        lines.append(f"-- 6. Production cautions")
        lines.append(f"--    {q.caution}")
        lines.append(f"-- 7. Required privileges")
        lines.append(f"--    {q.privileges}")
        if q.ebs:
            lines.append(f"-- EBS relevance  : {q.ebs}")
        if q.notes:
            lines.append("--")
            for n in q.notes.split("\n"):
                lines.append(f"-- {n}" if n.strip() else "--")
        lines.append("-" * 80)
        lines.append(q.sql.rstrip())
        lines.append("")
        lines.append("PROMPT")
        lines.append(f"PROMPT === End of query: {q.title} ===")
        lines.append("PROMPT")
        lines.append("")

    lines.append("-- End of file")
    lines.append("")

    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))

    INDEX_ROWS.append(
        {
            "Category": script.category,
            "Script Name": script.file_name,
            "Purpose": script.purpose,
            "Difficulty": script.difficulty,
            "Production Safe": script.production_use,
            "Required Privilege": script.privileges,
            "Oracle Version": script.oracle_version,
            "EBS": script.ebs,
            "Folder": script.folder,
            "Path": os.path.relpath(path, os.path.dirname(ROOT)),
        }
    )
    return path


def write_many(scripts: Iterable[Script]) -> int:
    count = 0
    for s in scripts:
        write_script(s)
        count += 1
    return count
