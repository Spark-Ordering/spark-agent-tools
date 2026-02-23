#!/usr/bin/env python3
"""
File-level merge state machine.

Simple approach: work one file at a time, agents must read all 3 versions
(base, dev1, dev2) before proposing or approving.

STATES:
- INIT: Starting state
- REVIEWING: Agents are reviewing/editing the current file
- PROPOSAL_PENDING: One agent proposed, waiting for other to approve
- FILE_COMPLETE: Both approved, ready for next file
- DONE: All files complete
"""

import json
import time
from pathlib import Path
from typing import Optional, List
import subprocess


STAGING_DIR = Path.home() / ".claude" / "merge-staging"


class FileMergeModel:
    """Model for file-level merge state."""

    def __init__(self):
        # Files to process
        self.all_files: List[str] = []
        self.file_index: int = 0
        self.current_file: Optional[str] = None

        # State
        self.state: str = "INIT"

        # Timestamp for staleness check
        self.file_started_at: float = 0.0

        # Seen tracking - reset per file and per proposal
        self.dev1_seen_base: bool = False
        self.dev1_seen_dev1: bool = False
        self.dev1_seen_dev2: bool = False
        self.dev2_seen_base: bool = False
        self.dev2_seen_dev1: bool = False
        self.dev2_seen_dev2: bool = False

        # Proposal
        self.proposal_comment: Optional[str] = None
        self.proposed_by: Optional[str] = None
        self.dev1_approved: bool = False
        self.dev2_approved: bool = False

        # Staging seen tracking - must see proposal before approving
        self.dev1_seen_staging: bool = False
        self.dev2_seen_staging: bool = False

        # Agent identity
        self.agent: Optional[str] = None

    def has_seen_all(self, agent: str) -> bool:
        """Check if agent has seen all 3 versions."""
        if agent == "dev1":
            return self.dev1_seen_base and self.dev1_seen_dev1 and self.dev1_seen_dev2
        else:
            return self.dev2_seen_base and self.dev2_seen_dev1 and self.dev2_seen_dev2

    def get_unseen_versions(self, agent: str) -> List[str]:
        """Get list of version names the agent hasn't seen yet."""
        unseen = []
        if agent == "dev1":
            if not self.dev1_seen_base:
                unseen.append("base")
            if not self.dev1_seen_dev1:
                unseen.append("dev1")
            if not self.dev1_seen_dev2:
                unseen.append("dev2")
        else:
            if not self.dev2_seen_base:
                unseen.append("base")
            if not self.dev2_seen_dev1:
                unseen.append("dev1")
            if not self.dev2_seen_dev2:
                unseen.append("dev2")
        return unseen

    def mark_seen(self, agent: str, which: str):
        """Mark that agent has seen a version."""
        if agent == "dev1":
            if which == "base":
                self.dev1_seen_base = True
            elif which == "dev1":
                self.dev1_seen_dev1 = True
            elif which == "dev2":
                self.dev1_seen_dev2 = True
            elif which == "staging":
                self.dev1_seen_staging = True
        else:
            if which == "base":
                self.dev2_seen_base = True
            elif which == "dev1":
                self.dev2_seen_dev1 = True
            elif which == "dev2":
                self.dev2_seen_dev2 = True
            elif which == "staging":
                self.dev2_seen_staging = True

    def reset_seen_for_file(self):
        """Reset seen flags when moving to new file."""
        self.dev1_seen_base = False
        self.dev1_seen_dev1 = False
        self.dev1_seen_dev2 = False
        self.dev2_seen_base = False
        self.dev2_seen_dev1 = False
        self.dev2_seen_dev2 = False
        self.dev1_seen_staging = False
        self.dev2_seen_staging = False

    def reset_approvals(self):
        """Reset approvals when new proposal is made."""
        self.dev1_approved = False
        self.dev2_approved = False

    def get_turn(self) -> Optional[str]:
        """Get whose turn it is."""
        if self.state == "INIT":
            return "dev1"
        elif self.state == "REVIEWING":
            return "dev1"  # Either can propose
        elif self.state == "PROPOSAL_PENDING":
            # Other agent's turn to approve
            return "dev2" if self.proposed_by == "dev1" else "dev1"
        elif self.state == "FILE_COMPLETE":
            return None
        elif self.state == "DONE":
            return None
        return None

    def is_my_turn(self) -> bool:
        """Check if it's this agent's turn."""
        turn = self.get_turn()
        if turn is None:
            return True  # Anyone can act in REVIEWING state
        return turn == self.agent

    def to_dict(self) -> dict:
        """Serialize to dict."""
        return {
            "all_files": self.all_files,
            "file_index": self.file_index,
            "current_file": self.current_file,
            "state": self.state,
            "file_started_at": self.file_started_at,
            "dev1_seen_base": self.dev1_seen_base,
            "dev1_seen_dev1": self.dev1_seen_dev1,
            "dev1_seen_dev2": self.dev1_seen_dev2,
            "dev2_seen_base": self.dev2_seen_base,
            "dev2_seen_dev1": self.dev2_seen_dev1,
            "dev2_seen_dev2": self.dev2_seen_dev2,
            "proposal_comment": self.proposal_comment,
            "proposed_by": self.proposed_by,
            "dev1_approved": self.dev1_approved,
            "dev2_approved": self.dev2_approved,
            "dev1_seen_staging": self.dev1_seen_staging,
            "dev2_seen_staging": self.dev2_seen_staging,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "FileMergeModel":
        """Deserialize from dict."""
        model = cls()
        model.all_files = data.get("all_files", [])
        model.file_index = data.get("file_index", 0)
        model.current_file = data.get("current_file")
        model.state = data.get("state", "INIT")
        model.file_started_at = data.get("file_started_at", 0.0)
        model.dev1_seen_base = data.get("dev1_seen_base", False)
        model.dev1_seen_dev1 = data.get("dev1_seen_dev1", False)
        model.dev1_seen_dev2 = data.get("dev1_seen_dev2", False)
        model.dev2_seen_base = data.get("dev2_seen_base", False)
        model.dev2_seen_dev1 = data.get("dev2_seen_dev1", False)
        model.dev2_seen_dev2 = data.get("dev2_seen_dev2", False)
        model.proposal_comment = data.get("proposal_comment")
        model.proposed_by = data.get("proposed_by")
        model.dev1_approved = data.get("dev1_approved", False)
        model.dev2_approved = data.get("dev2_approved", False)
        model.dev1_seen_staging = data.get("dev1_seen_staging", False)
        model.dev2_seen_staging = data.get("dev2_seen_staging", False)
        return model


def get_state_file() -> Path:
    """Get path to state file."""
    from merge_state import get_base_branch_from_git
    branch = get_base_branch_from_git().replace("/", "-")
    return Path.home() / ".claude" / "coordination" / f"file-merge-state-{branch}.json"


def save_model(model: FileMergeModel):
    """Save model to disk."""
    state_file = get_state_file()
    state_file.parent.mkdir(parents=True, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump(model.to_dict(), f, indent=2)


def load_model() -> FileMergeModel:
    """Load model from disk."""
    from merge_state import get_agent
    state_file = get_state_file()

    if state_file.exists():
        with open(state_file) as f:
            data = json.load(f)
        model = FileMergeModel.from_dict(data)
    else:
        model = FileMergeModel()

    model.agent = get_agent()
    return model


def get_file_versions(filepath: str) -> dict:
    """Get base, dev1, dev2 content for a file."""
    from merge_hunks import get_branch_info

    current, base, other = get_branch_info()

    # Fetch latest
    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    # Get merge base
    result = subprocess.run(
        ["git", "merge-base", f"origin/{base}-dev1", f"origin/{base}-dev2"],
        capture_output=True, text=True
    )
    merge_base = result.stdout.strip()

    # Get file contents
    base_content = subprocess.run(
        ["git", "show", f"{merge_base}:{filepath}"],
        capture_output=True, text=True
    ).stdout

    dev1_content = subprocess.run(
        ["git", "show", f"origin/{base}-dev1:{filepath}"],
        capture_output=True, text=True
    ).stdout

    dev2_content = subprocess.run(
        ["git", "show", f"origin/{base}-dev2:{filepath}"],
        capture_output=True, text=True
    ).stdout

    return {
        "base": base_content,
        "dev1": dev1_content,
        "dev2": dev2_content,
        "merge_base_ref": merge_base,
    }


def get_staging_path(filepath: str) -> Path:
    """Get staging path for a file."""
    return STAGING_DIR / filepath


def get_conflicting_files() -> List[str]:
    """Get list of files that differ between dev1 and dev2."""
    from merge_hunks import get_branch_info

    current, base, other = get_branch_info()

    # Fetch latest
    subprocess.run(["git", "fetch", "origin"], capture_output=True)

    # Get files that differ between dev1 and dev2
    result = subprocess.run(
        ["git", "diff", "--name-only", f"origin/{base}-dev1", f"origin/{base}-dev2"],
        capture_output=True, text=True
    )

    files = [f.strip() for f in result.stdout.strip().split("\n") if f.strip()]
    return files
