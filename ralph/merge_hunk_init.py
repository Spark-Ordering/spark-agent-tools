#!/usr/bin/env python3
"""Initialize hunk-based merge and status commands."""

from merge_state import get_agent, load_agent_state, load_state, save_state, log_action
from merge_git import get_branch_info, get_conflicting_files
from merge_hunks import get_file_hunks, get_all_hunks_unified


def cmd_start_hunks():
    """Initialize hunk-based merge workflow."""
    agent = get_agent()
    current, base, other = get_branch_info()

    print("Initializing hunk-based merge...")

    files = get_conflicting_files()
    if not files:
        print("No conflicts detected. Clean merge possible.")
        return

    print(f"Found {len(files)} files with overlapping changes:")

    my_state = load_agent_state(agent)
    my_state["phase"] = "hunks"
    my_state["base_branch"] = base
    my_state["whose_turn"] = "dev1"
    my_state["hunk_files"] = []

    for filepath in files:
        print(f"  Analyzing: {filepath}")
        file_info = get_file_hunks(filepath)
        unified_hunks = get_all_hunks_unified(file_info)

        my_state["hunk_files"].append({
            "filepath": filepath,
            "total_hunks": len(unified_hunks),
            "current_hunk": 0,
            "hunks_resolved": 0,
            "status": "pending"
        })
        print(f"    {len(unified_hunks)} hunks to resolve")

    if my_state["hunk_files"]:
        my_state["current_file_index"] = 0

    log_action(my_state, agent, f"started hunk merge for {len(files)} files")
    save_state(my_state)

    print("\nHUNK-BY-HUNK MERGE: Both agents build each file together.")
    print("Run: ralph merge show")


def cmd_hunk_status():
    """Show hunk merge status."""
    state = load_state()

    if state.get("phase") != "hunks":
        print("Not in hunk merge mode.")
        return

    hunk_files = state.get("hunk_files", [])
    current_idx = state.get("current_file_index", 0)

    print(f"Turn: {state.get('whose_turn')} | You: {get_agent()}\n")

    for i, fs in enumerate(hunk_files):
        current = " <--" if i == current_idx else ""
        icon = "R" if fs["status"] == "resolved" else "."
        print(f"[{icon}] {fs['filepath']}{current}")
        print(f"    {fs.get('hunks_resolved', 0)}/{fs['total_hunks']} hunks")
