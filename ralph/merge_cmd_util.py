#!/usr/bin/env python3
"""
Utility commands for ralph merge workflow.
Commands: status, reset, complete, wait, next-action
"""

import json
import subprocess
import time
from pathlib import Path

from merge_state import (
    COORD_DIR, get_agent, get_state_file, get_base_branch_from_git
)
from merge_git import get_branch_info
from merge_file_state import load_model
from merge_file_review import cmd_next_action as file_next_action


def cmd_status():
    """Show current merge status using file-level merge state."""
    model = load_model()
    agent = get_agent()

    print(f"State: {model.state}")
    print(f"Current file: {model.current_file or 'none'}")
    print(f"Turn: {model.get_turn()}")
    print(f"You are: {agent}")
    print()

    if not model.all_files:
        print("No files tracked.")
        return

    print(f"Progress: {model.file_index}/{len(model.all_files)} files\n")

    for i, filepath in enumerate(model.all_files):
        is_current = filepath == model.current_file
        is_done = i < model.file_index
        icon = "✓" if is_done else ("→" if is_current else " ")
        print(f"[{icon}] {filepath}")


def cmd_reset():
    """Clear all merge state on BOTH machines, including ralph-mode flags and staging."""
    base_branch = get_base_branch_from_git()
    safe_branch = base_branch.replace("/", "-")

    ralph_flag = str(Path.home() / ".claude" / ".ralph-mode")
    staging_dir = Path.home() / ".claude" / "merge-staging"

    files_to_clear = [
        str(COORD_DIR / "messages.txt"),
        str(COORD_DIR / f"merge-state-{safe_branch}-dev1.json"),
        str(COORD_DIR / f"merge-state-{safe_branch}-dev2.json"),
        str(COORD_DIR / f"file-merge-state-{safe_branch}.json"),  # File-level merge state
        ralph_flag,
    ]

    print("Clearing local state...")
    for f in files_to_clear:
        p = Path(f)
        if p.exists():
            p.unlink()
            print(f"   Deleted: {p.name}")

    # Clear staging directory
    if staging_dir.exists():
        import shutil
        shutil.rmtree(staging_dir)
        print(f"   Deleted: merge-staging/")

    print("Clearing remote state (dev2)...")
    remote_staging = "~/.claude/merge-staging"
    remote_cmd = f"rm -f {' '.join(files_to_clear)} && rm -rf {remote_staging}"
    result = subprocess.run(
        ["ssh", "carlos@192.168.1.104", remote_cmd],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print("   Remote cleared (including staging)")
    else:
        print(f"   Remote clear failed: {result.stderr.strip()}")

    print(f"\nReset complete for branch: {base_branch}")
    print("Ralph mode disabled on both machines.")


def cmd_complete():
    """Clean up after merge is complete."""
    current, base, other = get_branch_info()

    subprocess.run(["git", "checkout", base], capture_output=True)
    subprocess.run(["git", "branch", "-d", f"{base}-dev1"], capture_output=True)
    subprocess.run(["git", "branch", "-d", f"{base}-dev2"], capture_output=True)

    dev1_state_file = get_state_file("dev1", base)
    dev2_state_file = get_state_file("dev2", base)
    dev1_state_file.unlink(missing_ok=True)
    dev2_state_file.unlink(missing_ok=True)
    print(f"   Deleted merge state files for {base}")

    ralph_flag = Path.home() / ".claude" / ".ralph-mode"
    ralph_flag.unlink(missing_ok=True)

    print("Cleanup complete. Ralph mode disabled.")


def cmd_wait(seconds: int = 10) -> dict:
    """Wait the full time, then check what to do next."""
    time.sleep(seconds)

    # Use file-level merge state machine
    model = load_model()
    result = file_next_action()

    # Convert to expected format
    result = {
        "agent": result.get("agent"),
        "phase": result.get("state"),
        "current_file": model.current_file,
        "whose_turn": model.get_turn(),
        "action": result.get("actions", [None])[0] if result.get("actions") else None,
        "wait_for": result.get("wait_for"),
        "message": result.get("message", ""),
        "waited": seconds,
    }

    # Always show next action so agent knows what to do
    if result.get("action"):
        print(f">>> NEXT: {result['action']}")
    elif result.get("wait_for"):
        print(f">>> WAIT: Still waiting for {result['wait_for']}")

    return result


