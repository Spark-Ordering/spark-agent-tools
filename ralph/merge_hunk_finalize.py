#!/usr/bin/env python3
"""Finalize hunk merge - commit resolved files after state machine is DONE."""

import subprocess
from merge_state import get_agent
from merge_git import get_branch_info
from merge_hunk_state import load_model


def cmd_finalize_hunks():
    """Commit and push after all hunks resolved by state machine.

    The NEW state machine (merge_hunk_state.py) already applies proposals
    directly to conflict files via _apply_proposal_to_file() when reaching
    COMPLETE state. By the time we're in DONE state, all files are resolved.

    This function just needs to:
    1. Verify we're in DONE state
    2. Commit the resolved files
    3. Push to origin
    """
    agent = get_agent()

    # Check NEW state machine - must be in DONE state
    model = load_model()
    if model.state != "DONE":
        print(f"Not ready to finalize. State: {model.state}")
        print(f"All hunks must be resolved first.")
        return

    print("All hunks resolved. Committing...")

    current, base, other = get_branch_info()

    # Checkout base branch and merge both dev branches
    subprocess.run(["git", "checkout", base], capture_output=True)
    subprocess.run(["git", "pull", "origin", base], capture_output=True)
    subprocess.run(["git", "merge", f"origin/{base}-dev1", "--no-edit"], capture_output=True)
    subprocess.run(["git", "merge", f"origin/{base}-dev2", "--no-edit"], capture_output=True)

    # Stage and commit - files already resolved by state machine
    subprocess.run(["git", "add", "-A"])
    result = subprocess.run(
        ["git", "commit", "-m", "Merge: collaborative hunk resolution"],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        if "nothing to commit" in result.stdout or "nothing to commit" in result.stderr:
            print("Nothing to commit - files may already be committed.")
        else:
            print(f"Commit failed: {result.stderr}")
            return

    push_result = subprocess.run(
        ["git", "push", "origin", base],
        capture_output=True, text=True
    )

    if push_result.returncode != 0:
        print(f"Push failed: {push_result.stderr}")
        return

    print(f"\nMerge complete! Pushed to {base}")
    print("Run: ralph merge complete")
