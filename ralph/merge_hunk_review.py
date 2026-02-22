#!/usr/bin/env python3
"""Hunk review commands: show, propose, comment, agree."""

from merge_state import get_agent, load_agent_state, load_state, save_state, log_action, pass_turn
from merge_hunks import (
    get_file_hunks, get_all_hunks_unified, format_conflict_for_display,
    write_staging, read_staging, get_staging_path
)


def cmd_show_hunk():
    """Show current hunk with proposals and discussion."""
    state = load_state()
    agent = get_agent()

    if state.get("phase") != "hunks":
        print("Not in hunk mode. Run: ralph merge start")
        return

    hunk_files = state.get("hunk_files", [])
    current_idx = state.get("current_file_index", 0)

    if current_idx >= len(hunk_files):
        print("All files resolved! Run: ralph merge finalize")
        return

    fs = hunk_files[current_idx]
    filepath = fs["filepath"]
    current_hunk = fs.get("current_hunk", 0)
    total_hunks = fs.get("total_hunks", 1)

    print(f"{'='*60}")
    print(f"FILE: {filepath} (hunk {current_hunk + 1}/{total_hunks})")
    print(f"{'='*60}")

    # Show the original conflict
    file_info = get_file_hunks(filepath)
    unified = get_all_hunks_unified(file_info)

    if current_hunk < len(unified):
        hunk = unified[current_hunk]
        if hunk['type'] == 'conflict':
            print(format_conflict_for_display(hunk))
        elif hunk['type'] == 'dev1_only':
            print(f"\nDEV1-ONLY change at line {hunk['line_start']}:")
            if hunk['dev1_hunk']:
                print(hunk['dev1_hunk']['content'][:1500])
        else:
            print(f"\nDEV2-ONLY change at line {hunk['line_start']}:")
            if hunk['dev2_hunk']:
                print(hunk['dev2_hunk']['content'][:1500])

    # Show discussion history
    comments = fs.get("comments", [])
    if comments:
        print(f"\n{'─'*60}")
        print("DISCUSSION:")
        for c in comments[-10:]:  # Last 10 comments
            print(f"  [{c['by']}]: {c['text']}")

    # Show current proposal if any
    current_proposal = fs.get("current_proposal")
    proposed_by = fs.get("proposed_by")
    if current_proposal:
        print(f"\n{'─'*60}")
        print(f"CURRENT PROPOSAL by {proposed_by}:")
        print(current_proposal[:2000])

        # Show agreement status
        agreed = fs.get("agreed", {})
        dev1_agreed = "✓" if agreed.get("dev1") else "·"
        dev2_agreed = "✓" if agreed.get("dev2") else "·"
        print(f"\nAgreement: dev1[{dev1_agreed}] dev2[{dev2_agreed}]")

    print(f"\n{'─'*60}")
    print(f"Turn: {state.get('whose_turn')} | You: {agent}")
    print(f"\nTo propose a resolution:")
    print(f"  1. Write resolved code to ~/.claude/merge-staging/proposal.txt")
    print(f"  2. Run: ralph merge propose")
    print(f"\nOther actions:")
    print(f"  ralph merge comment '<text>'  - Add to discussion")
    if current_proposal:
        print(f"  ralph merge agree             - Signal you're satisfied")


def cmd_propose_hunk(code: str):
    """Propose a resolution. Clears previous agreement (new proposal needs fresh consensus)."""
    agent = get_agent()
    state = load_state()

    if state.get("whose_turn") != agent:
        print(f"Not your turn. Wait for {state.get('whose_turn')}.")
        return

    hunk_files = state.get("hunk_files", [])
    current_idx = state.get("current_file_index", 0)
    fs = hunk_files[current_idx]
    filepath = fs["filepath"]

    # Write to staging
    write_staging(filepath, code)

    # Update state
    my_state = load_agent_state(agent)
    if "hunk_files" not in my_state:
        my_state["hunk_files"] = hunk_files

    for f in my_state["hunk_files"]:
        if f["filepath"] == filepath:
            f["current_proposal"] = code
            f["proposed_by"] = agent
            # Clear agreement - new proposal needs fresh consensus
            f["agreed"] = {"dev1": False, "dev2": False}
            # Auto-agree to your own proposal
            f["agreed"][agent] = True
            break

    log_action(my_state, agent, f"proposed resolution for {filepath}")
    pass_turn(my_state, agent)
    save_state(my_state)

    other = "dev2" if agent == "dev1" else "dev1"
    print(f"Proposed resolution for {filepath}")
    print(f"You've auto-agreed. Waiting for {other} to review.")
    print(f"Turn -> {other}")


def cmd_comment_hunk(text: str):
    """Add a comment to the discussion."""
    agent = get_agent()
    state = load_state()

    if state.get("whose_turn") != agent:
        print(f"Not your turn. Wait for {state.get('whose_turn')}.")
        return

    hunk_files = state.get("hunk_files", [])
    current_idx = state.get("current_file_index", 0)
    fs = hunk_files[current_idx]
    filepath = fs["filepath"]

    my_state = load_agent_state(agent)
    if "hunk_files" not in my_state:
        my_state["hunk_files"] = hunk_files

    from datetime import datetime
    for f in my_state["hunk_files"]:
        if f["filepath"] == filepath:
            if "comments" not in f:
                f["comments"] = []
            f["comments"].append({
                "by": agent,
                "text": text,
                "time": datetime.now().isoformat()
            })
            break

    log_action(my_state, agent, f"commented on {filepath}")
    pass_turn(my_state, agent)
    save_state(my_state)

    other = "dev2" if agent == "dev1" else "dev1"
    print(f"Comment added. Turn -> {other}")


def cmd_agree_hunk():
    """Signal agreement with the current proposal."""
    agent = get_agent()
    state = load_state()

    if state.get("whose_turn") != agent:
        print(f"Not your turn.")
        return

    hunk_files = state.get("hunk_files", [])
    current_idx = state.get("current_file_index", 0)
    fs = hunk_files[current_idx]
    filepath = fs["filepath"]

    if not fs.get("current_proposal"):
        print("No proposal to agree to. Use: ralph merge propose '<code>'")
        return

    # Get the other agent's agreed status from MERGED state (fs)
    # my_state only has MY flags, not the other agent's
    other_agent = "dev2" if agent == "dev1" else "dev1"
    other_already_agreed = fs.get("agreed", {}).get(other_agent, False)

    my_state = load_agent_state(agent)
    if "hunk_files" not in my_state:
        my_state["hunk_files"] = hunk_files

    both_agreed = False
    for f in my_state["hunk_files"]:
        if f["filepath"] == filepath:
            if "agreed" not in f:
                f["agreed"] = {"dev1": False, "dev2": False}
            f["agreed"][agent] = True

            # Check if both agreed - use MERGED state for other agent's flag
            if other_already_agreed:
                both_agreed = True
                # Advance to next hunk
                current_hunk = f.get("current_hunk", 0)
                total = f.get("total_hunks", 1)
                f["current_hunk"] = current_hunk + 1
                f["hunks_resolved"] = current_hunk + 1
                # Clear for next hunk
                f["current_proposal"] = None
                f["proposed_by"] = None
                f["agreed"] = {"dev1": False, "dev2": False}
                f["comments"] = []

                if current_hunk + 1 >= total:
                    f["status"] = "resolved"
            break

    log_action(my_state, agent, f"agreed on {filepath}")

    if both_agreed:
        # Check if file is complete
        for f in my_state["hunk_files"]:
            if f["filepath"] == filepath:
                if f.get("status") == "resolved":
                    my_state["current_file_index"] = current_idx + 1
                    print(f"✓ {filepath} COMPLETE!")
                    if current_idx + 1 >= len(hunk_files):
                        print("\n🎉 ALL FILES DONE! Run: ralph merge finalize")
                    else:
                        next_file = hunk_files[current_idx + 1]["filepath"]
                        print(f"Next file: {next_file}")
                else:
                    hunk_num = f.get("current_hunk", 0) + 1
                    total = f.get("total_hunks", 1)
                    print(f"✓ Hunk resolved! Moving to hunk {hunk_num}/{total}")
                break
        # Reset turn to dev1 for next hunk
        my_state["whose_turn"] = "dev1"
    else:
        other = "dev2" if agent == "dev1" else "dev1"
        print(f"You agreed. Waiting for {other} to agree.")
        pass_turn(my_state, agent)

    save_state(my_state)


# Keep old names as aliases for compatibility
def cmd_write_hunk(resolved_code: str):
    """Alias for propose."""
    cmd_propose_hunk(resolved_code)


def cmd_approve_hunk():
    """Alias for agree."""
    cmd_agree_hunk()


def cmd_reject_hunk(reason: str):
    """Reject is now just a comment explaining disagreement."""
    cmd_comment_hunk(f"[DISAGREE] {reason}")
