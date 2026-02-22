#!/usr/bin/env python3
"""
Git operations for ralph merge workflow.
"""

import subprocess


def get_branch_info() -> tuple:
    """Get current branch, base branch, and other agent's branch."""
    current = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True
    ).stdout.strip()
    base = current.replace("-dev1", "").replace("-dev2", "")
    other = f"{base}-dev2" if current.endswith("-dev1") else f"{base}-dev1"
    return current, base, other


def get_conflicting_files() -> list:
    """Get list of files modified by both agents (potential conflicts)."""
    current, base, other = get_branch_info()
    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    result = subprocess.run(
        ["git", "merge-base", current, f"origin/{other}"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return []
    merge_base = result.stdout.strip()

    my_files = set(subprocess.run(
        ["git", "diff", "--name-only", merge_base, current],
        capture_output=True, text=True
    ).stdout.strip().split("\n"))

    their_files = set(subprocess.run(
        ["git", "diff", "--name-only", merge_base, f"origin/{other}"],
        capture_output=True, text=True
    ).stdout.strip().split("\n"))

    overlap = sorted(my_files & their_files)
    return [f for f in overlap if f]


def get_file_diff(filepath: str) -> dict:
    """Get diffs for a file from both agent branches."""
    current, base, other = get_branch_info()

    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    result = subprocess.run(
        ["git", "merge-base", current, f"origin/{other}"],
        capture_output=True, text=True
    )
    merge_base = result.stdout.strip()

    dev1_diff = subprocess.run(
        ["git", "diff", merge_base, f"origin/{base}-dev1", "--", filepath],
        capture_output=True, text=True
    ).stdout

    dev2_diff = subprocess.run(
        ["git", "diff", merge_base, f"origin/{base}-dev2", "--", filepath],
        capture_output=True, text=True
    ).stdout

    return {"dev1": dev1_diff, "dev2": dev2_diff}


def get_current_conflicts() -> list:
    """Get list of files with actual git conflict markers."""
    result = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=U"],
        capture_output=True, text=True
    )
    return [f for f in result.stdout.strip().split("\n") if f]
