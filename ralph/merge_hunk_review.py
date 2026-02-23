#!/usr/bin/env python3
"""
Hunk review commands: show, propose, approve.

Commands trigger events on the state machine.
The machine's callbacks handle all the logic.
"""

import time
from datetime import datetime
from pathlib import Path
from merge_state import get_agent, get_base_branch_from_git
from merge_hunks import (
    get_file_hunks, get_all_hunks_unified, format_conflict_for_display,
    get_staging_path, STAGING_DIR
)
from merge_hunk_state import load_model, save_model, format_state_display


def cmd_show_hunk():
    """Show current hunk with BASE, DEV1, DEV2 views and state."""
    model = load_model()
    agent = get_agent()

    if not model.filepath:
        print("No active hunk. Run: ralph merge start")
        return

    # Get file info with all content
    try:
        file_info = get_file_hunks(model.filepath)
        unified = get_all_hunks_unified(file_info)

        if model.hunk_index < len(unified):
            hunk = unified[model.hunk_index]

            # Display the three-way view
            print("=" * 60)
            print(f"HUNK {model.hunk_index + 1}/{model.total_hunks} at line {hunk['line_start']}")
            print("=" * 60)

            # Get line range for this hunk
            start_line = hunk['line_start'] - 1  # Convert to 0-indexed

            if hunk['type'] == 'conflict':
                dev1_count = hunk['dev1_hunk']['old_count'] if hunk['dev1_hunk'] else 0
                dev2_count = hunk['dev2_hunk']['old_count'] if hunk['dev2_hunk'] else 0
                span = max(dev1_count, dev2_count)
            else:
                h = hunk['dev1_hunk'] or hunk['dev2_hunk']
                span = h['old_count'] if h else 0

            end_line = start_line + span

            # Show BASE content for this region
            base_lines = file_info['base_content'].splitlines()
            print("\n=== BASE ===")
            for i, line in enumerate(base_lines[start_line:end_line], start=start_line+1):
                print(f"  {i}: {line}")

            # Show DEV1 changes
            print("\n=== DEV1 ===")
            if hunk['dev1_hunk']:
                print(hunk['dev1_hunk']['content'])
            else:
                print("  (no changes)")

            # Show DEV2 changes
            print("\n=== DEV2 ===")
            if hunk['dev2_hunk']:
                print(hunk['dev2_hunk']['content'])
            else:
                print("  (no changes)")

            print("")
            print("=" * 60)

    except Exception as e:
        print(f"(Could not load hunk details: {e})")
        print("")

    # Mark that this agent has seen the current hunk/proposal
    model.mark_seen(agent)
    save_model(model)

    # Show state machine state
    print(format_state_display(model))


def cmd_propose_hunk(filepath: str, comment: str):
    """
    Propose a resolution.

    Triggers dev1_propose or dev2_propose on the state machine.
    Writes proposal to a persistent file and verifies it was written.
    """
    model = load_model()
    agent = get_agent()

    if not model.is_my_turn():
        print(f"Not your turn. Wait for {model.get_turn()}.")
        return

    # Step 1: Read code from staging (agent must write here first)
    code = _read_proposal_code(model, agent)
    if not code:
        return

    if not comment or not comment.strip():
        print("ERROR: Comment is required.")
        print("Usage: ralph merge propose '<filepath>' '<comment>'")
        return

    trigger = f"{agent}_propose"

    try:
        getattr(model, trigger)(code=code, comment=comment)
    except Exception as e:
        print(f"ERROR: {e}")
        return

    save_model(model)

    # Step 2: Write proposal to persistent file for verification
    proposal_file = _write_proposal_file(model, agent, code, comment)
    if not proposal_file:
        print("ERROR: Failed to write proposal file!")
        return

    # Step 3: Verify the file was actually written
    if not proposal_file.exists():
        print(f"ERROR: Proposal file not found after write: {proposal_file}")
        return

    file_size = proposal_file.stat().st_size
    if file_size == 0:
        print(f"ERROR: Proposal file is empty: {proposal_file}")
        return

    other = "dev2" if agent == "dev1" else "dev1"
    print(f"Proposed resolution for {model.filepath}")
    print(f"Comment: \"{comment}\"")
    print(f"State: {model.state}")
    print(f"")
    print(f"✓ Proposal written: {proposal_file} ({file_size} bytes)")
    print(f"\nWaiting for {other} to run: ralph merge approve")


def cmd_approve_hunk():
    """
    Approve the current proposal.

    Triggers dev1_approve or dev2_approve on the state machine.
    """
    model = load_model()
    agent = get_agent()

    if not model.is_my_turn():
        print(f"Not your turn. Wait for {model.get_turn()}.")
        return

    if not model.proposal:
        print("No proposal to approve.")
        print("Someone must first run: ralph merge propose '<file>' '<comment>'")
        return

    # CRITICAL: Must have seen the proposal before approving
    # Prevents blind approvals based just on the comment
    if not model.has_seen_proposal(agent):
        print(f"ERROR: You must view the proposal before approving.")
        print(f"")
        print(f"Run 'ralph merge show' first to see the hunk and proposal.")
        print(f"Don't approve blindly based on the comment alone.")
        return

    trigger = f"{agent}_approve"

    try:
        getattr(model, trigger)()
    except Exception as e:
        print(f"ERROR: Cannot approve from state {model.state}: {e}")
        return

    save_model(model)

    if model.state == 'COMPLETE':
        print(f"Both approved! Hunk resolved.")
        print(f"State: {model.state}")
    else:
        other = "dev2" if agent == "dev1" else "dev1"
        print(f"You approved. Waiting for {other} to approve.")
        print(f"State: {model.state}")


def _read_proposal_code(model, agent: str) -> str:
    """
    Read proposal code from staging file.

    IMPORTANT: Validates that the staging file was modified AFTER the turn started.
    This prevents using stale files from previous turns.
    """
    if not model.filepath:
        print("ERROR: No active hunk filepath.")
        return None

    staging_path = get_staging_path(model.filepath)

    # Check staging file exists
    if not staging_path.exists():
        print(f"ERROR: Staging file not found.")
        print(f"Write your resolved code to: {staging_path}")
        return None

    # Check staging file has content
    code = staging_path.read_text()
    if not code or not code.strip():
        print(f"ERROR: Staging file is empty: {staging_path}")
        return None

    # CRITICAL: Reject proposals that contain conflict markers
    # This catches the bug where agents copy the conflicted file instead of writing resolved code
    if '<<<<<<<' in code or '>>>>>>>' in code or '=======' in code:
        print(f"ERROR: Proposal contains conflict markers!")
        print(f"")
        print(f"You copied the conflicted file. That's not how this works.")
        print(f"Write RESOLVED code to the staging file - no conflict markers.")
        print(f"")
        print(f"  Staging path: {staging_path}")
        return None

    # Check staging file was modified AFTER turn started
    file_mtime = staging_path.stat().st_mtime
    turn_started = model.turn_started_at

    if file_mtime < turn_started:
        file_time_str = datetime.fromtimestamp(file_mtime).strftime('%H:%M:%S')
        turn_time_str = datetime.fromtimestamp(turn_started).strftime('%H:%M:%S')
        print(f"ERROR: Staging file is STALE (from a previous turn).")
        print(f"  File modified at: {file_time_str}")
        print(f"  Turn started at:  {turn_time_str}")
        print(f"")
        print(f"You must write NEW content to the staging file for this turn.")
        print(f"  Staging path: {staging_path}")
        return None

    return code


def _write_proposal_file(model, agent: str, code: str, comment: str) -> Path:
    """
    Write proposal to a persistent file for verification.

    Returns the path to the written file, or None on failure.
    """
    branch = get_base_branch_from_git().replace("/", "-")

    proposal_dir = STAGING_DIR / "proposals"
    proposal_dir.mkdir(parents=True, exist_ok=True)

    proposal_file = proposal_dir / f"proposal-{branch}-{agent}.txt"

    try:
        content = f"# Proposal by {agent}\n"
        content += f"# File: {model.filepath}\n"
        content += f"# Hunk: {model.hunk_index + 1}/{model.total_hunks}\n"
        content += f"# Comment: {comment}\n"
        content += f"# Time: {datetime.now().isoformat()}\n"
        content += f"\n"
        content += code

        proposal_file.write_text(content)
        return proposal_file
    except Exception as e:
        print(f"ERROR writing proposal file: {e}")
        return None


def cmd_choose_hunk(choice: str):
    """
    Choose a resolution for the current hunk: dev1, dev2, both, or custom.

    This replaces manual staging - the tool computes the content based on choice
    and writes it to the staging file.

    Args:
        choice: One of 'dev1', 'dev2', 'both', or a path to a custom file
    """
    model = load_model()
    agent = get_agent()

    if not model.is_my_turn():
        print(f"Not your turn. Wait for {model.get_turn()}.")
        return

    if not model.filepath:
        print("ERROR: No active file. Run: ralph merge start")
        return

    # Get file info
    file_info = get_file_hunks(model.filepath)
    unified = get_all_hunks_unified(file_info)

    if model.hunk_index >= len(unified):
        print("ERROR: No more hunks to resolve.")
        return

    hunk = unified[model.hunk_index]

    # Compute the resolved content based on choice
    if choice == 'dev1':
        resolved_code = _compute_dev1_resolution(file_info, hunk)
        comment = "Take dev1's version"
    elif choice == 'dev2':
        resolved_code = _compute_dev2_resolution(file_info, hunk)
        comment = "Take dev2's version"
    elif choice == 'both':
        resolved_code = _compute_both_resolution(file_info, hunk)
        comment = "Combine both dev1 and dev2 changes"
    else:
        # Assume it's a path to custom content
        custom_path = Path(choice)
        if not custom_path.exists():
            print(f"ERROR: Custom file not found: {choice}")
            print("Usage: ralph merge choose <dev1|dev2|both|/path/to/file>")
            return
        resolved_code = custom_path.read_text()
        comment = "Custom resolution"

    if not resolved_code:
        print("ERROR: Could not compute resolution.")
        return

    # Write to staging file
    staging_path = _update_staging_with_choice(model, file_info, hunk, resolved_code)
    if not staging_path:
        return

    # Read the full staged file content for the state machine
    full_staged = staging_path.read_text()

    # Trigger the state machine
    trigger = f"{agent}_propose"
    try:
        getattr(model, trigger)(code=full_staged, comment=comment)
    except Exception as e:
        print(f"ERROR: {e}")
        return

    save_model(model)

    other = "dev2" if agent == "dev1" else "dev1"
    print(f"Choice '{choice}' staged for {model.filepath}")
    print(f"Hunk {model.hunk_index + 1}/{model.total_hunks}: {comment}")
    print(f"State: {model.state}")
    print(f"\nWaiting for {other} to run: ralph merge approve")


def _compute_dev1_resolution(file_info: dict, hunk: dict) -> str:
    """Compute what taking dev1's version looks like for this hunk."""
    # Start from base, apply dev1's changes
    if hunk['dev1_hunk']:
        return hunk['dev1_hunk']['content']
    return ""


def _compute_dev2_resolution(file_info: dict, hunk: dict) -> str:
    """Compute what taking dev2's version looks like for this hunk."""
    if hunk['dev2_hunk']:
        return hunk['dev2_hunk']['content']
    return ""


def _compute_both_resolution(file_info: dict, hunk: dict) -> str:
    """
    Compute combined resolution (both dev1 and dev2 changes).

    For non-overlapping additions, this concatenates them.
    For conflicting changes, this may need manual intervention.
    """
    dev1_content = hunk['dev1_hunk']['content'] if hunk['dev1_hunk'] else ""
    dev2_content = hunk['dev2_hunk']['content'] if hunk['dev2_hunk'] else ""

    # Simple concatenation - for real conflicts, user should use 'custom'
    if dev1_content and dev2_content:
        return dev1_content + "\n" + dev2_content
    return dev1_content or dev2_content


def _update_staging_with_choice(model, file_info: dict, hunk: dict, resolved_code: str) -> Path:
    """
    Update the staging file with the resolved hunk.

    If no staging file exists, create from base content.
    Then apply the resolved hunk to the appropriate line range.

    Returns the staging path, or None on error.
    """
    staging_path = get_staging_path(model.filepath)

    # Initialize from base if not exists
    if not staging_path.exists():
        staging_path.parent.mkdir(parents=True, exist_ok=True)
        staging_path.write_text(file_info['base_content'])

    # Read current staging
    current = staging_path.read_text()
    lines = current.splitlines(keepends=True)

    # Get line range for this hunk (convert to 0-indexed)
    start = hunk['line_start'] - 1

    if hunk['type'] == 'conflict':
        dev1_count = hunk['dev1_hunk']['old_count'] if hunk['dev1_hunk'] else 0
        dev2_count = hunk['dev2_hunk']['old_count'] if hunk['dev2_hunk'] else 0
        span = max(dev1_count, dev2_count)
    else:
        h = hunk['dev1_hunk'] or hunk['dev2_hunk']
        span = h['old_count'] if h else 0

    end = start + span

    # Replace the lines in that range with resolved content
    resolved_lines = resolved_code.splitlines(keepends=True)
    if resolved_lines and not resolved_lines[-1].endswith('\n'):
        resolved_lines[-1] += '\n'

    new_lines = lines[:start] + resolved_lines + lines[end:]
    new_content = ''.join(new_lines)

    staging_path.write_text(new_content)
    return staging_path
