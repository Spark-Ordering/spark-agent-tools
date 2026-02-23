#!/usr/bin/env python3
"""
Hunk merge navigation - next action from state machine.
"""

from merge_state import get_agent
from merge_hunk_state import load_model


def cmd_hunk_next_action() -> dict:
    """
    Get next action for hunk workflow from the state machine.

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
        "actions": [],  # List of ALL valid actions
        "wait_for": None,
        "message": ""
    }

    if not model.filepath:
        if agent == "dev1":
            result["actions"] = ["ralph merge start"]
            result["message"] = "Start hunk-by-hunk merge"
        else:
            result["wait_for"] = "dev1"
            result["message"] = "Waiting for dev1 to start merge"
        return result

    if model.state == "COMPLETE":
        result["message"] = "Both approved - advance to next hunk"
        return result

    if model.is_my_turn():
        result["actions"] = model.get_actions()
        result["message"] = f"Your turn: {model.state}"
    else:
        result["wait_for"] = model.get_turn()
        result["message"] = f"Waiting for {result['wait_for']}"

    return result
