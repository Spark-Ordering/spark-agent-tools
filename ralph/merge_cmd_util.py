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
    COORD_DIR, get_agent, get_state_file, get_base_branch_from_git,
    load_agent_state, load_state, save_state
)
from merge_git import get_branch_info


def cmd_status():
    """Show current merge status."""
    state = load_state()
    agent = get_agent()

    print(f"Phase: {state.get('phase', 'idle')}")
    print(f"Current file: {state.get('current_file', 'none')}")
    print(f"Turn: {state.get('whose_turn', 'dev1')}")
    print(f"You are: {agent}")
    print()

    files = state.get("files", {})
    if not files:
        print("No files tracked.")
        return

    approved = sum(1 for f in files.values() if f.get("status") == "approved")
    resolved = sum(1 for f in files.values() if f.get("resolved"))
    print(f"Progress: {approved}/{len(files)} approved, {resolved}/{len(files)} resolved\n")

    for path, info in files.items():
        status = info.get("status", "pending")
        res = info.get("resolved", False)
        icon = "R" if res else ("A" if status == "approved" else ("P" if status == "proposed" else "-"))
        current = " <--" if path == state.get("current_file") else ""
        discussed = info.get("discussed_by", [])
        print(f"[{icon}] {path}{current}")
        print(f"    discussed: {discussed}, votes: {info.get('votes', {})}")


def cmd_reset():
    """Clear all merge state on BOTH machines, including ralph-mode flags."""
    base_branch = get_base_branch_from_git()
    safe_branch = base_branch.replace("/", "-")

    ralph_flag = str(Path.home() / ".claude" / ".ralph-mode")

    files_to_clear = [
        str(COORD_DIR / "messages.txt"),
        str(COORD_DIR / f"merge-state-{safe_branch}-dev1.json"),
        str(COORD_DIR / f"merge-state-{safe_branch}-dev2.json"),
        ralph_flag,
    ]

    print("Clearing local state...")
    for f in files_to_clear:
        p = Path(f)
        if p.exists():
            p.unlink()
            print(f"   Deleted: {p.name}")

    print("Clearing remote state (dev2)...")
    remote_cmd = f"rm -f {' '.join(files_to_clear)}"
    result = subprocess.run(
        ["ssh", "carlos@192.168.1.104", remote_cmd],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print("   Remote cleared")
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
    from merge_hunk_nav import cmd_hunk_next_action

    time.sleep(seconds)

    state = load_state()
    if state.get("phase") == "hunks":
        result = cmd_hunk_next_action()
    else:
        result = cmd_next_action()

    result["waited"] = seconds
    return result


def cmd_next_action() -> dict:
    """TURN-ENFORCED next action - the core state machine."""
    agent = get_agent()
    state = load_state()
    phase = state.get("phase", "idle")
    current_file = state.get("current_file")
    whose_turn = state.get("whose_turn", "dev1")

    result = {
        "agent": agent,
        "phase": phase,
        "current_file": current_file,
        "whose_turn": whose_turn,
        "action": None,
        "wait_for": None,
        "message": ""
    }

    # GLOBAL TURN CHECK - dev1 ALWAYS goes first in idle/started phases
    if phase in ("idle", "started") and agent == "dev2":
        dev1_state = load_agent_state("dev1")
        if dev1_state.get("phase", "idle") not in ("review", "applying", "resolved", "clean", "merged"):
            result["wait_for"] = "dev1"
            result["message"] = "Waiting for dev1 to start merge first. Use 'ralph merge wait' to poll (do NOT write your own loop)."
            return result

    # TURN CHECK for review phase
    if phase == "review" and whose_turn != agent:
        result["wait_for"] = whose_turn
        result["message"] = f"Not your turn. Waiting for {whose_turn}. Use 'ralph merge wait' to poll (do NOT write your own loop)."
        return result

    if phase == "idle":
        result["action"] = "ralph merge start"
        result["message"] = "Start merge phase"
        return result

    if phase == "started":
        result["action"] = "ralph merge check"
        result["message"] = "Check for conflicts"
        return result

    if phase == "clean":
        result["action"] = "ralph merge execute"
        result["message"] = "No conflicts - execute merge"
        return result

    if phase == "merged":
        result["action"] = "ralph merge complete"
        result["message"] = "Cleanup"
        return result

    # === APPLYING PHASE - iterate through files ===
    if phase == "applying":
        if current_file:
            file_state = state["files"].get(current_file, {})
            if not file_state.get("resolved"):
                result["action"] = "ralph merge show-resolution"
                result["message"] = f"Apply resolution to: {current_file}"
                return result

        # All files resolved or no current file
        all_resolved = all(f.get("resolved") for f in state.get("files", {}).values())
        if all_resolved:
            result["action"] = "ralph merge finalize"
            result["message"] = "All files resolved - finalize merge"
        else:
            # Find next unresolved
            for f, info in state.get("files", {}).items():
                if not info.get("resolved"):
                    result["action"] = "ralph merge show-resolution"
                    result["current_file"] = f
                    result["message"] = f"Apply resolution to: {f}"
                    break
        return result

    if phase == "resolved":
        result["action"] = "ralph merge finalize"
        result["message"] = "All files resolved - finalize merge"
        return result

    # === REVIEW PHASE - discussion workflow ===
    if not current_file:
        files = state.get("files", {})
        all_approved = all(f.get("status") == "approved" for f in files.values())
        if all_approved and files:
            result["action"] = "ralph merge apply"
            result["message"] = "All files approved - start applying resolutions"
        else:
            result["action"] = "ralph merge check"
            result["message"] = "No current file"
        return result

    file_state = state["files"].get(current_file, {})
    discussed_by = file_state.get("discussed_by", [])
    proposal = file_state.get("proposal")
    votes = file_state.get("votes", {})
    other = "dev2" if agent == "dev1" else "dev1"

    # Haven't discussed yet
    if agent not in discussed_by:
        result["action"] = f'ralph merge discuss "<your analysis of {current_file}>"'
        result["message"] = f"Discuss {current_file}"
        return result

    # Both discussed, no proposal - I should propose
    if len(discussed_by) >= 2 and not proposal:
        result["action"] = f'ralph merge propose "<resolution for {current_file}>"'
        result["message"] = "Both discussed - propose resolution"
        return result

    # Proposal exists, I haven't voted
    if proposal and not votes.get(agent):
        result["action"] = "ralph merge vote approve"
        result["message"] = f"Vote on proposal: {proposal[:50]}"
        return result

    result["action"] = "ralph merge show"
    result["message"] = "Show current file"
    return result
