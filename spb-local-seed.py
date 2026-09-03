#!/usr/bin/env python3
"""Re-emit a mysqldump's INSERTs against the CURRENT schema (used by spb-local.sh).

The dump's CREATE TABLE blocks give the column order its VALUES tuples were
written in; the live table may have gained or lost columns since. For each
table we keep only the columns that still exist and emit explicit-column
REPLACE INTO statements, so re-running is idempotent.

Usage: spb-local-seed.py <dump.sql> <container> <db> <user> <pass> > out.sql
"""
import re
import subprocess
import sys

dump_path, container, db, user, password = sys.argv[1:6]
text = open(dump_path, encoding="utf-8").read()

dump_cols = {}
for m in re.finditer(r"CREATE TABLE `(\w+)` \((.*?)\n\)", text, re.S):
    dump_cols[m.group(1)] = re.findall(r"^\s+`(\w+)`", m.group(2), re.M)


def live_cols(table):
    out = subprocess.run(
        ["docker", "exec", container, "mysql", f"-u{user}", f"-p{password}", "-N", "-e",
         f"SELECT column_name FROM information_schema.columns WHERE table_schema='{db}' "
         f"AND table_name='{table}' ORDER BY ordinal_position"],
        capture_output=True, text=True, check=True,
    ).stdout
    return [c for c in out.split("\n") if c and not c.startswith("mysql:")]


def split_tuples(values_sql):
    """Split `(a,b),(c,d)` into per-row lists of raw SQL literals, quote-aware."""
    rows, row, field, depth, quote, i = [], [], [], 0, None, 0
    while i < len(values_sql):
        ch = values_sql[i]
        if quote:
            field.append(ch)
            if ch == "\\":
                field.append(values_sql[i + 1])
                i += 1
            elif ch == quote:
                quote = None
        elif ch in ("'", '"'):
            quote = ch
            field.append(ch)
        elif ch == "(":
            depth += 1
            if depth > 1:
                field.append(ch)
        elif ch == ")":
            depth -= 1
            if depth == 0:
                row.append("".join(field).strip())
                rows.append(row)
                row, field = [], []
            else:
                field.append(ch)
        elif ch == "," and depth == 1:
            row.append("".join(field).strip())
            field = []
        elif depth >= 1:
            field.append(ch)
        i += 1
    return rows


print("SET FOREIGN_KEY_CHECKS=0;")
for m in re.finditer(r"^INSERT INTO `(\w+)` VALUES (.*);$", text, re.M):
    table, values_sql = m.group(1), m.group(2)
    src = dump_cols[table]
    live = live_cols(table)
    keep = [i for i, c in enumerate(src) if c in live]
    dropped = [c for c in src if c not in live]
    print(f"-- {table}: {len(src)} dump cols -> {len(keep)} kept; dropped={dropped}", file=sys.stderr)
    col_list = ", ".join(f"`{src[i]}`" for i in keep)
    for row in split_tuples(values_sql):
        if len(row) != len(src):
            print(f"-- {table}: row with {len(row)} values (expected {len(src)}) skipped", file=sys.stderr)
            continue
        print(f"REPLACE INTO `{table}` ({col_list}) VALUES ({', '.join(row[i] for i in keep)});")
print("SET FOREIGN_KEY_CHECKS=1;")
