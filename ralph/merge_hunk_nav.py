#!/usr/bin/env python3
"""Hunk merge navigation - next action logic."""

from merge_state import get_agent, load_state


def cmd_hunk_next_action() -> dict:
    """Get next action for hunk workflow."""
    agent = get_agent()
    state = load_state()
    whose_turn = state.get("whose_turn", "dev1")

    result = {
        "agent": agent,
        "phase": state.get("phase"),
        "whose_turn": whose_turn,
        "action": None,
        "wait_for": None,
        "message": ""
    }

    if state.get("phase") != "hunks":
        # Not started yet - tell dev1 to start
        if agent == "dev1":
            result["action"] = "ralph merge start"
            result["message"] = "Start hunk-by-hunk merge"
        else:
            result["wait_for"] = "dev1"
            result["message"] = "Waiting for dev1 to start merge"
        return result

    if whose_turn != agent:
        result["wait_for"] = whose_turn
        result["message"] = f"Waiting for {whose_turn}"
        return result

    hunk_files = state.get("hunk_files", [])
    idx = state.get("current_file_index", 0)

    if idx >= len(hunk_files):
        result["action"] = "ralph merge finalize"
        result["message"] = "All resolved - finalize"
        return result

    fs = hunk_files[idx]
    filepath = fs.get("filepath", "unknown")
    current_proposal = fs.get("current_proposal")
    agreed = fs.get("agreed", {})
    my_agreed = agreed.get(agent, False)

    if current_proposal:
        if my_agreed:
            # I already agreed, waiting for other
            other = "dev2" if agent == "dev1" else "dev1"
            result["wait_for"] = other
            result["message"] = f"You agreed. Waiting for {other} to agree on {filepath}"
        else:
            # There's a proposal I haven't agreed to yet
            result["action"] = "ralph merge show"
            result["message"] = f"Review proposal for {filepath} - agree, comment, or propose alternative"
    else:
        # No proposal yet
        result["action"] = "ralph merge show"
        result["message"] = f"View {filepath} - propose resolution or comment"

    return result
