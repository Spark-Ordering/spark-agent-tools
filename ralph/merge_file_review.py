#!/usr/bin/env python3
"""
File-level merge review commands.

Commands trigger state machine transitions:
- ralph merge start           # Trigger: begin()
- ralph merge show           # Display status
- ralph merge show base      # Show base content, mark seen
- ralph merge show dev1      # Show dev1 content, mark seen
- ralph merge show dev2      # Show dev2 content, mark seen
- ralph merge show staging   # Show staging content, mark seen
- ralph merge propose '<filepath>' '<comment>'  # Trigger: dev1_propose/dev2_propose
- ralph merge approve        # Trigger: dev1_approve/dev2_approve
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


def cmd_show():
    """
    Show ALL versions of the current file (base, dev1, dev2, and staging if exists).
    Marks the agent as having seen the file, enabling propose/approve.
    """
    model = load_model()
    agent = get_agent()

    if model.state == "INIT":
        print("No merge in progress. Run: ralph merge start")
        return

    if model.state == "DONE":
        print("Merge complete! All files resolved.")
        print("Run: ralph merge finalize")
        return

    if not model.current_file:
        print("No current file set.")
        return

    filepath = model.current_file

    # Get all versions
    try:
        versions = get_file_versions(filepath)
    except Exception as e:
        print(f"Error getting file versions: {e}")
        return

    # Show header
    print("=" * 70)
    print(f"FILE: {filepath}")
    print(f"Progress: {model.file_index + 1}/{len(model.all_files)}")
    print(f"State: {model.state}")
    print("=" * 70)

    # Show BASE version
    print()
    print(">>> BASE VERSION (common ancestor):")
    print("-" * 70)
    base_content = versions.get("base", "")
    if base_content:
        print(base_content)
    else:
        print("(no base content)")
    print()

    # Show DEV1 version
    print(">>> DEV1 VERSION:")
    print("-" * 70)
    dev1_content = versions.get("dev1", "")
    if dev1_content:
        print(dev1_content)
    else:
        print("(no dev1 content)")
    print()

    # Show DEV2 version
    print(">>> DEV2 VERSION:")
    print("-" * 70)
    dev2_content = versions.get("dev2", "")
    if dev2_content:
        print(dev2_content)
    else:
        print("(no dev2 content)")
    print()

    # Show STAGING if it exists
    staging_path = get_staging_path(filepath)
    if staging_path.exists():
        print(">>> STAGING (proposed resolution):")
        print(f"    Proposed by: {model.proposed_by or 'unknown'}")
        print(f"    Comment: {model.proposal_comment or 'none'}")
        print("-" * 70)
        print(staging_path.read_text())
        print()

    # Mark as seen
    model.mark_seen(agent)
    save_model(model)

    print("=" * 70)
    print(f"✓ {agent} has seen all versions.")

    # ADVOCACY INSTRUCTIONS - show when reviewing other agent's proposal
    if model.proposed_by and model.proposed_by != agent:
        print()
        print("⚠️  ADVOCACY CHECK:")
        print(f"   You are {agent}. This proposal is from {model.proposed_by}.")
        print("   ADVOCATE for your branch's work. If your files/exports are being")
        print("   excluded, COUNTER-PROPOSE. Don't approve deletion of your own work.")

    # Show next action
    print()
    if model.is_my_turn():
        if model.state == "NO_PROPOSAL_DEV1":
            print("YOUR TURN: Write resolved file to staging, then propose:")
            print(f"  ralph merge propose '{filepath}' '<your comment>'")
        else:
            print("YOUR TURN: Approve or counter-propose:")
            print("  ralph merge approve")
            print(f"  ralph merge propose '{filepath}' '<counter-comment>'")
    else:
        print(f"WAITING: {model.get_turn()}'s turn.")
    print("=" * 70)


def cmd_start():
    """Start a new file-level merge session.

    Triggers: begin() → CHECK_REMAINING → CHECKING_FILE → NO_PROPOSAL_DEV1
    """
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

    # Initialize file list
    model.all_files = files
    model.file_index = 0

    # Trigger state machine: INIT → CHECK_REMAINING (auto-advances)
    model.begin()

    save_model(model)

    if model.state == "DONE":
        print("All files are identical - nothing to merge.")
        return

    print()
    print("Next: ralph merge show")


def cmd_propose(filepath: str, comment: str):
    """Propose the staging file as the resolution.

    Triggers: dev1_propose or dev2_propose based on agent
    """
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

    # Validate has run show
    if not model.has_seen(agent):
        print("ERROR: You must run 'ralph merge show' before proposing.")
        print("Run: ralph merge show")
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
        model.reject_markers()
        save_model(model)
        return

    # Check staging file was modified AFTER this agent ran 'show'
    file_mtime = staging_path.stat().st_mtime
    last_show_at = model.dev1_last_show_at if agent == "dev1" else model.dev2_last_show_at

    if last_show_at == 0.0:
        print("ERROR: You must run 'ralph merge show' before proposing.")
        return

    if file_mtime < last_show_at:
        file_time_str = datetime.fromtimestamp(file_mtime).strftime('%H:%M:%S')
        show_time_str = datetime.fromtimestamp(last_show_at).strftime('%H:%M:%S')
        print("ERROR: Staging file is STALE (not written after you ran 'show').")
        print(f"  Staging file modified: {file_time_str}")
        print(f"  You ran 'show' at:     {show_time_str}")
        print()
        print("You must write NEW content to the staging file after reviewing.")
        print(f"  Staging path: {staging_path}")
        return

    if not comment or not comment.strip():
        print("ERROR: Comment is required.")
        print("Usage: ralph merge propose '<filepath>' '<comment>'")
        return

    # If we were in REJECTED state but staging is now clean, transition out first
    if model.state == "REJECTED":
        model.fix_markers()

    # Trigger the appropriate proposal transition
    try:
        if agent == "dev1":
            model.dev1_propose(comment=comment)
        else:
            model.dev2_propose(comment=comment)
    except Exception as e:
        print(f"ERROR: {e}")
        return

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
    """Approve the current proposal.

    Triggers: dev1_approve or dev2_approve based on agent
    """
    model = load_model()
    agent = get_agent()

    # Check we're in a proposal state
    proposal_states = (
        "PROPOSAL_DEV2_NEITHER",
        "PROPOSAL_DEV1_DEV2_APPROVED",
        "PROPOSAL_DEV1_NEITHER",
        "PROPOSAL_DEV2_DEV1_APPROVED",
    )
    if model.state not in proposal_states:
        print(f"No proposal to approve. State: {model.state}")
        return

    if not model.is_my_turn():
        print(f"Not your turn. Wait for {model.get_turn()}.")
        return

    # Validate has run show
    if not model.has_seen(agent):
        print("ERROR: You must run 'ralph merge show' before approving.")
        print("Run: ralph merge show")
        return

    # Trigger the appropriate approval transition
    try:
        if agent == "dev1":
            model.dev1_approve()
        else:
            model.dev2_approve()
    except Exception as e:
        print(f"ERROR: {e}")
        return

    save_model(model)

    # Check final state
    if model.state == "DONE":
        print()
        print("=" * 60)
        print("ALL FILES MERGED!")
        print("=" * 60)
        print()
        print("Staging directory: ~/.claude/merge-staging/")
        print("Run: ralph merge finalize")
    elif model.state in ("PROPOSAL_DEV1_DEV2_APPROVED", "PROPOSAL_DEV2_DEV1_APPROVED"):
        other = "dev2" if agent == "dev1" else "dev1"
        print(f"You approved. Waiting for {other} to approve.")
    elif model.state == "NO_PROPOSAL_DEV1":
        # Advanced to next file
        print()
        print(f"Advanced to file {model.file_index + 1}/{len(model.all_files)}: {model.current_file}")
        print("Run 'ralph merge show' to see status.")


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


def cmd_finalize():
    """Finalize merge after all files resolved by state machine.

    1. Verify we're in DONE state
    2. Checkout base branch
    3. Merge dev1 and dev2 (gets all changes, creates conflicts in overlapping files)
    4. Copy staging files over conflicted files (the agreed resolutions)
    5. Commit and push
    """
    agent = get_agent()

    # Check state machine - must be in DONE state
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
            "actions": list,
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

    # Handle based on state
    if model.state == "INIT":
        if agent == "dev1":
            result["actions"] = ["ralph merge start"]
            result["message"] = "Start file-level merge"
        else:
            result["wait_for"] = "dev1"
            result["message"] = "Waiting for dev1 to start merge"
        return result

    if model.state == "DONE":
        result["actions"] = ["ralph merge finalize"]
        result["message"] = "All files merged - finalize"
        return result

    # Check if it's my turn
    if model.is_my_turn():
        # Must run 'show' first
        if not model.has_seen(agent):
            result["actions"] = ["ralph merge show"]
            result["message"] = "Run 'show' to see all versions"
            return result

        # In NO_PROPOSAL state, dev1 proposes
        if model.state == "NO_PROPOSAL_DEV1":
            result["actions"] = [
                f"ralph merge propose '{model.current_file}' '<comment>'",
            ]
            result["message"] = f"Your turn: propose resolution for {model.current_file}"
            return result

        # In proposal states, can approve or counter-propose
        if model.state in ("PROPOSAL_DEV2_NEITHER", "PROPOSAL_DEV1_DEV2_APPROVED",
                           "PROPOSAL_DEV1_NEITHER", "PROPOSAL_DEV2_DEV1_APPROVED"):
            result["actions"] = [
                "ralph merge approve",
                f"ralph merge propose '{model.current_file}' '<counter-comment>'",
            ]
            result["message"] = f"Your turn: approve or counter-propose ({model.proposed_by}'s proposal)"
            return result

        # Error states
        if model.state == "REJECTED":
            result["actions"] = [f"ralph merge propose '{model.current_file}' '<comment>'"]
            result["message"] = "Fix staging file (remove conflict markers) and propose again"
            return result

    else:
        # Not my turn - wait
        result["wait_for"] = model.get_turn()
        result["message"] = f"Waiting for {result['wait_for']}"

    return result
