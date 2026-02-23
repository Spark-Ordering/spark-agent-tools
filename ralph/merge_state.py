#!/usr/bin/env python3
"""
State management for ralph merge workflow.
Core utilities for agent detection and coordination.
"""

import os
import subprocess
from pathlib import Path

COORD_DIR = Path.home() / ".claude" / "coordination"

# Single source of truth for turn - lives on dev2's machine
TURN_FILE = "/Users/carlos/.claude/coordination/turn.txt"
DEV2_HOST = "carlos@192.168.1.104"


def read_turn() -> str:
    """Read whose turn from the single source of truth (dev2's machine)."""
    agent = get_agent()

    if agent == "dev2":
        # Local read
        turn_path = Path(TURN_FILE)
        if turn_path.exists():
            return turn_path.read_text().strip()
        return "dev1"  # Default: dev1 goes first

    # dev1: SSH to dev2 to read
    try:
        result = subprocess.run(
            ["ssh", "-o", "ConnectTimeout=3", DEV2_HOST, f"cat {TURN_FILE} 2>/dev/null || echo dev1"],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip() or "dev1"
    except:
        return "dev1"


def toggle_turn() -> bool:
    """Toggle turn to the other agent. Only succeeds if it's currently our turn."""
    agent = get_agent()
    current = read_turn()

    # Verification: can only toggle if it's MY turn
    if current != agent:
        print(f"Cannot toggle turn: it's {current}'s turn, not {agent}'s")
        return False

    other = "dev2" if agent == "dev1" else "dev1"

    if agent == "dev2":
        # Local write
        turn_path = Path(TURN_FILE)
        turn_path.parent.mkdir(parents=True, exist_ok=True)
        turn_path.write_text(other)
        return True

    # dev1: SSH to dev2 to write
    try:
        result = subprocess.run(
            ["ssh", "-o", "ConnectTimeout=3", DEV2_HOST, f"mkdir -p $(dirname {TURN_FILE}) && echo {other} > {TURN_FILE}"],
            capture_output=True, text=True, timeout=5
        )
        return result.returncode == 0
    except:
        return False


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
