#!/usr/bin/env python3
"""Finalize hunk merge - apply staging files to repo."""

import subprocess
from merge_state import get_agent, load_agent_state, load_state, save_state, log_action
from merge_git import get_branch_info
from merge_hunks import apply_staging_to_repo


def cmd_finalize_hunks():
    """Apply all staging files and commit."""
    agent = get_agent()
    state = load_state()
    hunk_files = state.get("hunk_files", [])

    for fs in hunk_files:
        if fs["status"] != "resolved":
            print(f"Not resolved: {fs['filepath']}")
            return

    print("Applying staged files...")

    current, base, other = get_branch_info()

    subprocess.run(["git", "checkout", base], capture_output=True)
    subprocess.run(["git", "pull", "origin", base], capture_output=True)
    subprocess.run(["git", "merge", f"origin/{base}-dev1", "--no-edit"], capture_output=True)
    subprocess.run(["git", "merge", f"origin/{base}-dev2", "--no-edit"], capture_output=True)

    for fs in hunk_files:
        print(f"  {fs['filepath']}")
        try:
            apply_staging_to_repo(fs["filepath"])
        except FileNotFoundError:
            print(f"    WARNING: No staging file")

    subprocess.run(["git", "add", "-A"])
    subprocess.run(["git", "commit", "-m", "Merge: collaborative hunk resolution"])
    subprocess.run(["git", "push", "origin", base])

    my_state = load_agent_state(agent)
    my_state["phase"] = "merged"
    log_action(my_state, agent, "finalized")
    save_state(my_state)

    print("\nMerge complete! Run: ralph merge complete")
