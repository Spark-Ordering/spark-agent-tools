#!/usr/bin/env python3
"""Initialize hunk-based merge and status commands."""

from merge_state import get_agent, load_agent_state, load_state, save_state, log_action, read_turn
from merge_git import get_branch_info, get_conflicting_files
from merge_hunks import get_file_hunks, get_all_hunks_unified
from merge_hunk_state import HunkModel, create_machine, save_model


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

    # Initialize legacy state (for backward compat during transition)
    my_state = load_agent_state(agent)
    my_state["phase"] = "hunks"
    my_state["base_branch"] = base
    my_state["hunk_files"] = []

    all_hunks = []

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
        all_hunks.append({
            "filepath": filepath,
            "total_hunks": len(unified_hunks)
        })
        print(f"    {len(unified_hunks)} hunks to resolve")

    if my_state["hunk_files"]:
        my_state["current_file_index"] = 0

    log_action(my_state, agent, f"started hunk merge for {len(files)} files")
    save_state(my_state)

    # Initialize state machine model with first file
    if all_hunks:
        first = all_hunks[0]
        model = HunkModel()
        model.filepath = first["filepath"]
        model.hunk_index = 0
        model.total_hunks = first["total_hunks"]
        model.agent = agent

        # Create machine at initial state
        create_machine(model, initial_state='NO_PROPOSAL_DEV1')

        # Save the model
        save_model(model)

    print("\nHUNK-BY-HUNK MERGE: Both agents build each file together.")
    print("Run: ralph merge show")


def cmd_hunk_status():
    """Show hunk merge status from NEW state machine."""
    from merge_hunk_state import load_model

    model = load_model()

    if not model.filepath:
        print("Not in hunk merge mode. Run: ralph merge start")
        return

    agent = get_agent()
    is_my_turn = model.is_my_turn()

    print(f"State: {model.state}")
    print(f"Your turn: {'YES' if is_my_turn else 'NO'}")
    print(f"You are: {agent}")
    print()
    print(f"File: {model.filepath}")
    print(f"Hunk: {model.hunk_index + 1}/{model.total_hunks}")
    print()
    print(f"Approvals: dev1={'✓' if model.dev1_approved else '-'} dev2={'✓' if model.dev2_approved else '-'}")

    if model.proposal:
        print(f"Proposal by: {model.proposed_by}")
        if model.proposal_comment:
            print(f"Comment: {model.proposal_comment[:80]}")

    print()
    if is_my_turn:
        actions = model.get_actions()
        if actions:
            print("YOUR OPTIONS:")
            for i, action in enumerate(actions, 1):
                print(f"  {i}. {action}")
    else:
        print(f"WAITING for {model.get_turn()}")
