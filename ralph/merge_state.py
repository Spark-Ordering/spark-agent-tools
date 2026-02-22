#!/usr/bin/env python3
"""
State management for ralph merge workflow.
Handles loading, saving, and merging state between agents.
"""

import io
import json
import os
import subprocess
from pathlib import Path
from datetime import datetime

COORD_DIR = Path.home() / ".claude" / "coordination"


def get_base_branch_from_git() -> str:
    """Get base branch from current git branch (strips -dev1/-dev2 suffix)."""
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True
    )
    current = result.stdout.strip()
    return current.replace("-dev1", "").replace("-dev2", "")


def get_state_file(agent: str, base_branch: str = None) -> Path:
    """Get state file path. Includes base branch for isolation between branches."""
    if not base_branch:
        base_branch = get_base_branch_from_git()
    safe_branch = base_branch.replace("/", "-")
    return COORD_DIR / f"merge-state-{safe_branch}-{agent}.json"


def get_agent() -> str:
    """Detect which agent we are (dev1 or dev2)."""
    identity_file = Path.home() / ".claude" / "agent-identity"
    if identity_file.exists():
        agent = identity_file.read_text().strip()
        if agent in ("dev1", "dev2"):
            return agent

    env_agent = os.environ.get("RALPH_AGENT", "")
    if env_agent in ("dev1", "dev2"):
        return env_agent

    ralph_flag = Path.home() / ".claude" / ".ralph-mode"
    if ralph_flag.exists():
        content = ralph_flag.read_text().strip()
        if ":" in content:
            agent = content.split(":")[0]
            if agent in ("dev1", "dev2"):
                return agent
        elif content in ("dev1", "dev2"):
            return content

    hostname = subprocess.run(["hostname"], capture_output=True, text=True).stdout.strip().lower()
    if any(x in hostname for x in ["macbook-air", "mac.attlocal", "mac.local"]):
        return "dev1"
    if any(x in hostname for x in ["macbook-pro", "carloss-macbook"]):
        return "dev2"

    return "unknown"


def empty_state() -> dict:
    """Return an empty state structure."""
    return {
        "phase": "idle",
        "whose_turn": "dev1",
        "current_file": None,
        "base_branch": None,
        "files": {},
        "history": [],
        "applying_conflicts": False
    }


def load_agent_state(agent: str) -> dict:
    """Load agent state - use SSH for remote agent to get real-time state."""
    my_agent = get_agent()
    state_file = get_state_file(agent)

    # If reading OUR OWN state, read locally
    if agent == my_agent:
        if not state_file.exists():
            return empty_state()
        try:
            with open(state_file) as f:
                return json.load(f)
        except:
            return empty_state()

    # Reading OTHER agent's state - SSH for real-time (avoids sync lag)
    if my_agent == "dev1" and agent == "dev2":
        other_host = "carlos@192.168.1.104"
    elif my_agent == "dev2" and agent == "dev1":
        other_host = "carlos@192.168.1.148"
    else:
        other_host = None

    if other_host:
        try:
            result = subprocess.run(
                ["ssh", "-o", "ConnectTimeout=3", other_host, f"cat {state_file} 2>/dev/null"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.load(io.StringIO(result.stdout))
        except:
            pass

    # Fallback: read synced local copy
    if not state_file.exists():
        return empty_state()
    try:
        with open(state_file) as f:
            return json.load(f)
    except:
        return empty_state()


def merge_states(dev1_state: dict, dev2_state: dict) -> dict:
    """Merge both agent states. TURN is determined by most recent action."""
    # Phase priority - higher = more progressed. "hunks" is the active merge state.
    phase_priority = {"idle": 0, "started": 1, "hunks": 2, "review": 3, "applying": 4, "resolved": 5, "clean": 6, "merged": 7}
    p1 = phase_priority.get(dev1_state.get("phase", "idle"), 0)
    p2 = phase_priority.get(dev2_state.get("phase", "idle"), 0)
    phase = dev1_state.get("phase") if p1 >= p2 else dev2_state.get("phase")

    current_file = dev1_state.get("current_file") or dev2_state.get("current_file")
    base_branch = dev1_state.get("base_branch") or dev2_state.get("base_branch")
    applying_conflicts = dev1_state.get("applying_conflicts") or dev2_state.get("applying_conflicts")

    # TURN: check whose_turn from both states, use most recently set
    h1 = dev1_state.get("history", [])
    h2 = dev2_state.get("history", [])
    last_t1 = h1[-1]["time"] if h1 else ""
    last_t2 = h2[-1]["time"] if h2 else ""

    if last_t1 > last_t2:
        whose_turn = dev1_state.get("whose_turn", "dev1")
    elif last_t2 > last_t1:
        whose_turn = dev2_state.get("whose_turn", "dev1")
    else:
        whose_turn = dev1_state.get("whose_turn") or dev2_state.get("whose_turn") or "dev1"

    # Merge files
    merged_files = {}
    all_file_paths = set(dev1_state.get("files", {}).keys()) | set(dev2_state.get("files", {}).keys())

    for filepath in all_file_paths:
        f1 = dev1_state.get("files", {}).get(filepath, {})
        f2 = dev2_state.get("files", {}).get(filepath, {})

        discussed_by = list(set(f1.get("discussed_by", [])) | set(f2.get("discussed_by", [])))

        all_discussions = f1.get("discussion", []) + f2.get("discussion", [])
        seen = set()
        discussions = []
        for d in sorted(all_discussions, key=lambda x: x.get("time", "")):
            key = (d.get("time"), d.get("agent"))
            if key not in seen:
                seen.add(key)
                discussions.append(d)

        votes = {
            "dev1": f1.get("votes", {}).get("dev1") or f2.get("votes", {}).get("dev1"),
            "dev2": f1.get("votes", {}).get("dev2") or f2.get("votes", {}).get("dev2")
        }

        proposal = f1.get("proposal") or f2.get("proposal")
        proposed_by = f1.get("proposed_by") or f2.get("proposed_by")
        resolved = f1.get("resolved") or f2.get("resolved")

        if votes["dev1"] == "APPROVE" and votes["dev2"] == "APPROVE":
            status = "approved"
        elif proposal:
            status = "proposed"
        else:
            status = "pending"

        merged_files[filepath] = {
            "status": status,
            "discussed_by": discussed_by,
            "discussion": discussions,
            "proposal": proposal,
            "proposed_by": proposed_by,
            "votes": votes,
            "resolved": resolved
        }

    # Merge history
    all_history = dev1_state.get("history", []) + dev2_state.get("history", [])
    seen_history = set()
    history = []
    for h in sorted(all_history, key=lambda x: x.get("time", "")):
        key = (h.get("time"), h.get("agent"), h.get("action"))
        if key not in seen_history:
            seen_history.add(key)
            history.append(h)

    # Merge hunk_files (used by hunk workflow)
    # Must merge per-file state like pending_review, proposed_by, etc.
    hf1 = dev1_state.get("hunk_files", [])
    hf2 = dev2_state.get("hunk_files", [])

    if hf1 and hf2 and len(hf1) == len(hf2):
        # Merge each file's state
        hunk_files = []
        for f1, f2 in zip(hf1, hf2):
            # Merge comments from both agents
            c1 = f1.get("comments", [])
            c2 = f2.get("comments", [])
            all_comments = c1 + c2
            seen_comments = set()
            merged_comments = []
            for c in sorted(all_comments, key=lambda x: x.get("time", "")):
                key = (c.get("time"), c.get("by"))
                if key not in seen_comments:
                    seen_comments.add(key)
                    merged_comments.append(c)

            # Determine if file is resolved
            is_resolved = f1.get("status") == "resolved" or f2.get("status") == "resolved"
            status = "resolved" if is_resolved else f1.get("status", "pending") or f2.get("status", "pending")

            # Take max of hunk progress
            current_hunk = max(f1.get("current_hunk", 0), f2.get("current_hunk", 0))
            hunks_resolved = max(f1.get("hunks_resolved", 0), f2.get("hunks_resolved", 0))
            total_hunks = max(f1.get("total_hunks", 0), f2.get("total_hunks", 0))

            # Merge agreed flags
            # KEY FIX: If current_hunk has advanced (meaning both agreed at some point),
            # OR if the file is resolved, treat both as agreed for the CURRENT state
            a1 = f1.get("agreed", {})
            a2 = f2.get("agreed", {})

            # Check if the hunk has been advanced by either agent
            hunk_advanced = (f1.get("current_hunk", 0) != f2.get("current_hunk", 0))

            if is_resolved or hunk_advanced:
                # If one agent advanced, both must have agreed at that moment
                # The clearing of flags by the advancing agent shouldn't reset this
                merged_agreed = {"dev1": True, "dev2": True}
                # Clear proposal since hunk is done
                current_proposal = None
                proposed_by = None
            else:
                # Normal case: OR the flags from both agents
                merged_agreed = {
                    "dev1": a1.get("dev1") or a2.get("dev1"),
                    "dev2": a1.get("dev2") or a2.get("dev2"),
                }
                # Use most recent proposal
                prop1 = f1.get("current_proposal")
                prop2 = f2.get("current_proposal")
                current_proposal = prop1 or prop2
                proposed_by = f1.get("proposed_by") or f2.get("proposed_by")

            merged_file = {
                "filepath": f1.get("filepath") or f2.get("filepath"),
                "total_hunks": total_hunks,
                "current_hunk": current_hunk,
                "hunks_resolved": hunks_resolved,
                "status": status,
                "current_proposal": current_proposal,
                "proposed_by": proposed_by,
                "agreed": merged_agreed,
                "comments": merged_comments,
                # Legacy field
                "pending_review": f1.get("pending_review") or f2.get("pending_review"),
            }
            hunk_files.append(merged_file)
    else:
        hunk_files = hf1 or hf2 or []

    current_file_index = max(
        dev1_state.get("current_file_index", 0),
        dev2_state.get("current_file_index", 0)
    )

    return {
        "phase": phase,
        "whose_turn": whose_turn,
        "current_file": current_file,
        "base_branch": base_branch,
        "files": merged_files,
        "history": history,
        "applying_conflicts": applying_conflicts,
        "hunk_files": hunk_files,
        "current_file_index": current_file_index
    }


def load_state() -> dict:
    """Load merged state from both agents."""
    dev1_state = load_agent_state("dev1")
    dev2_state = load_agent_state("dev2")
    return merge_states(dev1_state, dev2_state)


def save_state(state: dict):
    """Save state to this agent's state file."""
    agent = get_agent()
    if agent not in ("dev1", "dev2"):
        print(f"ERROR: Cannot save state - unknown agent: {agent}")
        return
    COORD_DIR.mkdir(parents=True, exist_ok=True)
    state_file = get_state_file(agent)
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)


def log_action(state: dict, agent: str, action: str):
    """Log an action to state history."""
    state["history"].append({
        "time": datetime.now().isoformat(),
        "agent": agent,
        "action": action
    })


def pass_turn(state: dict, agent: str):
    """Pass turn to the other agent."""
    other = "dev2" if agent == "dev1" else "dev1"
    state["whose_turn"] = other
