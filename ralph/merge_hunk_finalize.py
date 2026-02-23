#!/usr/bin/env python3
"""Finalize hunk merge - commit resolved files after state machine is DONE."""

import subprocess
from pathlib import Path
from merge_state import get_agent
from merge_git import get_branch_info
from merge_hunk_state import load_model
from merge_hunks import STAGING_DIR


def cmd_finalize_hunks():
    """Finalize merge after all hunks resolved by state machine.

    1. Verify we're in DONE state
    2. Checkout base branch
    3. Merge dev1 and dev2 (gets all changes, creates conflicts in overlapping files)
    4. Copy staging files over conflicted files (the agreed resolutions)
    5. Commit and push
    """
    agent = get_agent()

    # Check state machine - must be in DONE state OR all files auto-resolved
    model = load_model()
    if model.state != "DONE":
        print(f"Not ready to finalize. State: {model.state}")
        print(f"All hunks must be resolved first.")
        return

    current, base, other = get_branch_info()

    print(f"Finalizing merge onto {base}...")

    # Step 1: Checkout base branch
    print(f"  Checking out {base}...")
    checkout_result = subprocess.run(
        ["git", "checkout", base],
        capture_output=True, text=True
    )
    if checkout_result.returncode != 0:
        print(f"Failed to checkout {base}: {checkout_result.stderr}")
        return

    # Step 2: Pull latest base
    subprocess.run(["git", "pull", "origin", base], capture_output=True)

    # Step 3: Merge dev1
    print(f"  Merging {base}-dev1...")
    merge1_result = subprocess.run(
        ["git", "merge", f"origin/{base}-dev1", "--no-edit"],
        capture_output=True, text=True
    )
    # Don't fail on conflicts - we'll resolve them with staging files

    # Step 4: Merge dev2
    print(f"  Merging {base}-dev2...")
    merge2_result = subprocess.run(
        ["git", "merge", f"origin/{base}-dev2", "--no-edit"],
        capture_output=True, text=True
    )
    # Don't fail on conflicts - we'll resolve them with staging files

    # Step 5: Apply staging files (resolved versions) over any conflicts
    print("  Applying resolved files from staging...")
    applied = 0
    if STAGING_DIR.exists():
        for staging_file in STAGING_DIR.rglob("*"):
            if staging_file.is_file():
                rel_path = staging_file.relative_to(STAGING_DIR)
                # Write to repo (current working directory)
                dest_path = Path.cwd() / rel_path
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                dest_path.write_text(staging_file.read_text())
                print(f"    Applied: {rel_path}")
                applied += 1

    if applied == 0:
        print("  WARNING: No staging files found!")

    # Step 6: Stage and commit
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

    # Step 7: Push
    push_result = subprocess.run(
        ["git", "push", "origin", base],
        capture_output=True, text=True
    )

    if push_result.returncode != 0:
        print(f"Push failed: {push_result.stderr}")
        return

    print(f"\nMerge complete! Pushed to {base}")
    print("Run: ralph merge reset")
