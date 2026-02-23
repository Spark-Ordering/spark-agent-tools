#!/usr/bin/env python3
"""
File-level merge review commands.

Commands:
- ralph merge show           # Status: current file, what's been seen, state
- ralph merge show base      # Full base content, marks seen_base=true
- ralph merge show dev1      # Full dev1 content, marks seen_dev1=true
- ralph merge show dev2      # Full dev2 content, marks seen_dev2=true
- ralph merge show staging   # Full staging content (if exists)
- ralph merge propose '<comment>'  # Propose staging file as resolution
- ralph merge approve        # Approve current proposal
"""

import subprocess
import time
from datetime import datetime
from pathlib import Path
from merge_state import get_agent
from merge_git import get_branch_info
from merge_file_state import (
    load_model, save_model, get_staging_path, get_file_versions,
    get_conflicting_files, STAGING_DIR, FileMergeModel
)


def cmd_show(variant: str = None):
    """
    Show file content or status.

    variant=None: Show status (current file, seen flags, state)
    variant='base': Show base content, mark seen
    variant='dev1': Show dev1 content, mark seen
    variant='dev2': Show dev2 content, mark seen
    variant='staging': Show staging content
    """
    model = load_model()
    agent = get_agent()

    if model.state == "INIT":
        print("No merge in progress. Run: ralph merge start")
        return

    if model.state == "DONE":
        print("Merge complete! All files resolved.")
        return

    if not model.current_file:
        print("No current file. Run: ralph merge next")
        return

    if variant is None:
        _show_status(model, agent)
    elif variant == "base":
        _show_version(model, agent, "base")
    elif variant == "dev1":
        _show_version(model, agent, "dev1")
    elif variant == "dev2":
        _show_version(model, agent, "dev2")
    elif variant == "staging":
        _show_staging(model, agent)
    else:
        print(f"Unknown variant: {variant}")
        print("Usage: ralph merge show [base|dev1|dev2|staging]")


def _show_status(model: FileMergeModel, agent: str):
    """Show current merge status."""
    print("=" * 60)
    print(f"FILE: {model.current_file}")
    print(f"Progress: {model.file_index + 1}/{len(model.all_files)}")
    print(f"State: {model.state}")
    print("=" * 60)
    print()

    # Show seen flags for this agent
    if agent == "dev1":
        base_seen = "✓" if model.dev1_seen_base else "✗"
        dev1_seen = "✓" if model.dev1_seen_dev1 else "✗"
        dev2_seen = "✓" if model.dev1_seen_dev2 else "✗"
    else:
        base_seen = "✓" if model.dev2_seen_base else "✗"
        dev1_seen = "✓" if model.dev2_seen_dev1 else "✗"
        dev2_seen = "✓" if model.dev2_seen_dev2 else "✗"

    print(f"Your seen flags ({agent}):")
    print(f"  {base_seen} base  - ralph merge show base")
    print(f"  {dev1_seen} dev1  - ralph merge show dev1")
    print(f"  {dev2_seen} dev2  - ralph merge show dev2")
    print()

    has_seen_all = model.has_seen_all(agent)
    if has_seen_all:
        print("✓ You have seen all versions. You can propose or approve.")
    else:
        print("✗ You must see all versions before proposing or approving.")
    print()

    # Show proposal status
    if model.state == "PROPOSAL_PENDING":
        print(f"PROPOSAL by {model.proposed_by}:")
        print(f"  Comment: \"{model.proposal_comment}\"")
        print(f"  dev1 approved: {'✓' if model.dev1_approved else '✗'}")
        print(f"  dev2 approved: {'✓' if model.dev2_approved else '✗'}")
        print()
        print("View staging: ralph merge show staging")
        if model.is_my_turn():
            print("To approve: ralph merge approve")
    elif model.state == "REVIEWING":
        print("No proposal yet.")
        if has_seen_all:
            print("To propose: Write staging file, then: ralph merge propose '<comment>'")
        else:
            print("Read all versions first, then write staging and propose.")

    print()
    print("=" * 60)


def _show_version(model: FileMergeModel, agent: str, which: str):
    """Show a specific version (base, dev1, or dev2) and mark as seen."""
    filepath = model.current_file

    try:
        versions = get_file_versions(filepath)
        content = versions.get(which, "")

        if not content:
            print(f"No content for {which} version of {filepath}")
            return

        print("=" * 60)
        print(f"{which.upper()} VERSION: {filepath}")
        print("=" * 60)
        print()
        print(content)
        print()
        print("=" * 60)

        # Mark as seen
        model.mark_seen(agent, which)
        save_model(model)

        print(f"✓ Marked {which} as seen for {agent}")

        # Show remaining
        if agent == "dev1":
            remaining = []
            if not model.dev1_seen_base:
                remaining.append("base")
            if not model.dev1_seen_dev1:
                remaining.append("dev1")
            if not model.dev1_seen_dev2:
                remaining.append("dev2")
        else:
            remaining = []
            if not model.dev2_seen_base:
                remaining.append("base")
            if not model.dev2_seen_dev1:
                remaining.append("dev1")
            if not model.dev2_seen_dev2:
                remaining.append("dev2")

        if remaining:
            print(f"Still need to see: {', '.join(remaining)}")
        else:
            print("✓ You have seen all versions. Ready to propose or approve.")

    except Exception as e:
        print(f"Error getting {which} version: {e}")


def _show_staging(model: FileMergeModel, agent: str):
    """Show the current staging file content."""
    filepath = model.current_file
    staging_path = get_staging_path(filepath)

    if not staging_path.exists():
        print(f"No staging file exists yet for {filepath}")
        print(f"Write your resolved version to: {staging_path}")
        return

    content = staging_path.read_text()

    print("=" * 60)
    print(f"STAGING: {filepath}")
    print(f"Path: {staging_path}")
    print("=" * 60)
    print()
    print(content)
    print()
    print("=" * 60)

    # Mark that this agent has seen the current staging/proposal
    model.mark_seen(agent, "staging")
    save_model(model)

    # ADVOCACY INSTRUCTIONS - show when reviewing other agent's proposal
    if model.proposal_comment and model.proposed_by != agent:
        print("")
        print("\u26a0\ufe0f  ADVOCACY CHECK:")
        print(f"   You are {agent}. This proposal is from {model.proposed_by}.")
        print("   ADVOCATE for your branch's work. If your files/exports are being")
        print("   excluded, COUNTER-PROPOSE. Don't approve deletion of your own work.")


def cmd_start():
    """Start a new file-level merge session."""
    model = load_model()

    if model.state not in ["INIT", "DONE"]:
        print(f"Merge already in progress. State: {model.state}")
        print("Run 'ralph merge show' to see status.")
        return

    # Get list of conflicting files
    files = get_conflicting_files()

    if not files:
        print("No files differ between dev1 and dev2.")
        return

    print(f"Found {len(files)} files to merge:")
    for i, f in enumerate(files, 1):
        print(f"  {i}. {f}")
    print()

    # Initialize model
    model.all_files = files
    model.file_index = 0
    model.current_file = files[0]
    model.state = "REVIEWING"
    model.file_started_at = time.time()
    model.reset_seen_for_file()
    model.reset_approvals()
    model.proposal_comment = None
    model.proposed_by = None

    save_model(model)

    print(f"Starting with file 1/{len(files)}: {files[0]}")
    print()
    print("Next steps:")
    print("  1. ralph merge show base   - See base version")
    print("  2. ralph merge show dev1   - See dev1 version")
    print("  3. ralph merge show dev2   - See dev2 version")
    print("  4. Write resolved file to staging")
    print("  5. ralph merge propose '<comment>'")


def cmd_propose(filepath: str, comment: str):
    """Propose the staging file as the resolution."""
    model = load_model()
    agent = get_agent()

    if model.state == "INIT":
        print("No merge in progress. Run: ralph merge start")
        return

    if model.state == "DONE":
        print("Merge already complete.")
        return

    if not model.current_file:
        print("No current file.")
        return

    # Check if it's this agent's turn
    if not model.is_my_turn():
        print(f"ERROR: Not your turn. Wait for {model.get_turn()}.")
        return

    # Validate filepath matches current file
    if filepath != model.current_file:
        print(f"ERROR: Filepath mismatch.")
        print(f"  You specified: {filepath}")
        print(f"  Current file:  {model.current_file}")
        print()
        print("Use the current file path in your propose command.")
        return

    # Validate seen all versions
    if not model.has_seen_all(agent):
        print("ERROR: You must see all 3 versions before proposing.")
        print()
        print("Run these commands first:")
        if agent == "dev1":
            if not model.dev1_seen_base:
                print("  ralph merge show base")
            if not model.dev1_seen_dev1:
                print("  ralph merge show dev1")
            if not model.dev1_seen_dev2:
                print("  ralph merge show dev2")
        else:
            if not model.dev2_seen_base:
                print("  ralph merge show base")
            if not model.dev2_seen_dev1:
                print("  ralph merge show dev1")
            if not model.dev2_seen_dev2:
                print("  ralph merge show dev2")
        return

    # Check staging file exists
    staging_path = get_staging_path(model.current_file)
    if not staging_path.exists():
        print(f"ERROR: No staging file found.")
        print(f"Write your resolved version to: {staging_path}")
        return

    # Check staging file has content
    content = staging_path.read_text()
    if not content.strip():
        print(f"ERROR: Staging file is empty: {staging_path}")
        return

    # Check for conflict markers
    if '<<<<<<<' in content or '>>>>>>>' in content or '=======' in content:
        print("ERROR: Staging file contains conflict markers!")
        print("Write RESOLVED code without conflict markers.")
        return

    # Check staging file was modified AFTER file started
    file_mtime = staging_path.stat().st_mtime
    file_started = model.file_started_at

    if file_mtime < file_started:
        file_time_str = datetime.fromtimestamp(file_mtime).strftime('%H:%M:%S')
        start_time_str = datetime.fromtimestamp(file_started).strftime('%H:%M:%S')
        print("ERROR: Staging file is STALE (from a previous file).")
        print(f"  File modified at:   {file_time_str}")
        print(f"  Current file started: {start_time_str}")
        print()
        print("You must write NEW content to the staging file for this file.")
        print(f"  Staging path: {staging_path}")
        return

    if not comment or not comment.strip():
        print("ERROR: Comment is required.")
        print("Usage: ralph merge propose '<filepath>' '<comment>'")
        return

    # Update state
    model.state = "PROPOSAL_PENDING"
    model.proposal_comment = comment
    model.proposed_by = agent
    model.reset_approvals()

    # RESET SEEN TRACKING - new proposal must be viewed before approving
    model.dev1_seen_staging = False
    model.dev2_seen_staging = False

    # Proposer auto-approves
    if agent == "dev1":
        model.dev1_approved = True
    else:
        model.dev2_approved = True

    save_model(model)

    other = "dev2" if agent == "dev1" else "dev1"
    print(f"Proposed resolution for {model.current_file}")
    print(f"Comment: \"{comment}\"")
    print(f"State: {model.state}")
    print()
    print(f"Waiting for {other} to:")
    print(f"  1. ralph merge show staging  - Review your proposal")
    print(f"  2. ralph merge approve       - Approve it")


def cmd_approve():
    """Approve the current proposal."""
    model = load_model()
    agent = get_agent()

    if model.state != "PROPOSAL_PENDING":
        print(f"No proposal to approve. State: {model.state}")
        return

    if not model.is_my_turn():
        print(f"Not your turn. Wait for {model.get_turn()}.")
        return

    # Validate seen all versions
    if not model.has_seen_all(agent):
        print("ERROR: You must see all 3 versions before approving.")
        print()
        print("Run 'ralph merge show' to see which versions you still need to read.")
        return

    # CRITICAL: Must have seen the proposal before approving
    # Prevents blind approvals based just on the comment
    has_seen_staging = model.dev1_seen_staging if agent == "dev1" else model.dev2_seen_staging
    if not has_seen_staging:
        print(f"ERROR: You must view the proposal before approving.")
        print(f"")
        print(f"Run 'ralph merge show staging' first to see the staging file and proposal.")
        print(f"Don't approve blindly based on the comment alone.")
        return

    # Mark approved
    if agent == "dev1":
        model.dev1_approved = True
    else:
        model.dev2_approved = True

    # Check if both approved
    if model.dev1_approved and model.dev2_approved:
        print(f"Both approved! File {model.current_file} resolved.")

        # Apply staging to repo
        _apply_staging(model)

        # Move to next file
        model.file_index += 1
        if model.file_index >= len(model.all_files):
            model.state = "DONE"
            model.current_file = None
            print()
            print("=" * 60)
            print("ALL FILES MERGED!")
            print("=" * 60)
            print()
            print("Staging directory: ~/.claude/merge-staging/")
            print("Review and commit the changes.")
        else:
            model.current_file = model.all_files[model.file_index]
            model.state = "REVIEWING"
            model.file_started_at = time.time()
            model.reset_seen_for_file()
            model.reset_approvals()
            model.proposal_comment = None
            model.proposed_by = None
            print()
            print(f"Next file ({model.file_index + 1}/{len(model.all_files)}): {model.current_file}")
            print()
            print("Run 'ralph merge show' to see status.")
    else:
        other = "dev2" if agent == "dev1" else "dev1"
        print(f"You approved. Waiting for {other} to approve.")

    save_model(model)


def _apply_staging(model: FileMergeModel):
    """Copy staging file to actual repo location."""
    staging_path = get_staging_path(model.current_file)
    if not staging_path.exists():
        print(f"WARNING: Staging file not found: {staging_path}")
        return

    content = staging_path.read_text()

    # Write to actual file
    target = Path(model.current_file)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content)

    # Stage for commit
    subprocess.run(["git", "add", model.current_file])

    print(f"Applied staging to {model.current_file}")


def cmd_next():
    """Move to the next file (for recovery/skip scenarios)."""
    model = load_model()

    if model.state == "INIT":
        print("No merge in progress. Run: ralph merge start")
        return

    if model.state == "DONE":
        print("Merge already complete.")
        return

    model.file_index += 1
    if model.file_index >= len(model.all_files):
        model.state = "DONE"
        model.current_file = None
        print("No more files. Merge complete.")
    else:
        model.current_file = model.all_files[model.file_index]
        model.state = "REVIEWING"
        model.file_started_at = time.time()
        model.reset_seen_for_file()
        model.reset_approvals()
        model.proposal_comment = None
        model.proposed_by = None
        print(f"Moved to file {model.file_index + 1}/{len(model.all_files)}: {model.current_file}")

    save_model(model)


def cmd_finalize():
    """Finalize merge after all files resolved by state machine.

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
        print(f"All files must be resolved first.")
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
        ["git", "commit", "-m", "Merge: collaborative file resolution"],
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


def cmd_next_action() -> dict:
    """
    Get next action for file-level merge workflow from the state machine.

    Returns:
        {
            "agent": str,
            "state": str,
            "actions": list,  # ALL valid actions for this state
            "wait_for": str | None,
            "message": str,
        }
    """
    agent = get_agent()
    model = load_model()

    result = {
        "agent": agent,
        "state": model.state,
        "actions": [],
        "wait_for": None,
        "message": "",
    }

    # --- INIT: no merge started yet ---
    if model.state == "INIT":
        if agent == "dev1":
            result["actions"] = ["ralph merge start"]
            result["message"] = "Start file-level merge"
        else:
            result["wait_for"] = "dev1"
            result["message"] = "Waiting for dev1 to start merge"
        return result

    # --- DONE: all files resolved ---
    if model.state == "DONE":
        result["actions"] = ["ralph merge finalize"]
        result["message"] = "All files merged - finalize"
        return result

    # --- REVIEWING: agents read versions, then propose ---
    if model.state == "REVIEWING":
        unseen = model.get_unseen_versions(agent)

        if not unseen:
            result["actions"] = [
                f"ralph merge propose '{model.current_file}' '<comment>'",
            ]
            result["message"] = f"Your turn: seen all versions, ready to propose ({model.current_file})"
        else:
            result["actions"] = [f"ralph merge show {v}" for v in unseen]
            result["message"] = f"Your turn: read remaining versions ({', '.join(unseen)})"
        return result

    # --- PROPOSAL_PENDING: one agent proposed, other must approve ---
    if model.state == "PROPOSAL_PENDING":
        if model.is_my_turn():
            unseen = model.get_unseen_versions(agent)

            if unseen:
                result["actions"] = [f"ralph merge show {v}" for v in unseen]
                result["message"] = f"Your turn: read remaining versions before approving ({', '.join(unseen)})"
            else:
                has_seen_staging = model.dev1_seen_staging if agent == "dev1" else model.dev2_seen_staging

                if not has_seen_staging:
                    result["actions"] = ["ralph merge show staging"]
                    result["message"] = f"Your turn: review staging proposal by {model.proposed_by}"
                else:
                    result["actions"] = [
                        "ralph merge approve",
                        f"ralph merge propose '{model.current_file}' '<counter-comment>'",
                    ]
                    result["message"] = f"Your turn: approve or counter-propose ({model.proposed_by}'s proposal)"
        else:
            result["wait_for"] = model.get_turn()
            result["message"] = f"Waiting for {result['wait_for']} to review proposal"
        return result

    # Fallback for unexpected states
    result["message"] = f"Unknown state: {model.state}"
    return result
